---
{"dg-publish":true,"date":"2023-12-10","time":"10:46","progress":"进行中","tags":["cpp","协程"],"permalink":"/编程语言/C++/协程/渡劫 C++ 协程（8）：通用 Awaiter/","dgPassFrontmatter":true}
---

# 渡劫 C++ 协程（8）：通用 Awaiter

* [渡劫 C++ 协程（0）：前言](https://www.bennyhuo.com/2022/03/06/cpp-coroutines-00-foreword/)
* [渡劫 C++ 协程（1）：C++ 协程概览](https://www.bennyhuo.com/2022/03/09/cpp-coroutines-01-intro/)
* [渡劫 C++ 协程（2）：实现一个序列生成器](https://www.bennyhuo.com/2022/03/11/cpp-coroutines-02-generator/)
* [渡劫 C++ 协程（3）：序列生成器的泛化和函数式变换](https://www.bennyhuo.com/2022/03/14/cpp-coroutines-03-functional/)
* [渡劫 C++ 协程（4）：通用异步任务 Task](https://www.bennyhuo.com/2022/03/19/cpp-coroutines-04-task/)
* [渡劫 C++ 协程（5）：协程的调度器](https://www.bennyhuo.com/2022/03/20/cpp-coroutines-05-dispatcher/)
* [渡劫 C++ 协程（6）：基于协程的挂起实现无阻塞的 sleep](https://www.bennyhuo.com/2022/03/20/cpp-coroutines-06-sleep/)
* [渡劫 C++ 协程（7）：用于协程之间消息传递的 Channel](https://www.bennyhuo.com/2022/03/22/cpp-coroutines-07-channel/)
* [渡劫 C++ 协程（8）：通用 Awaiter](https://www.bennyhuo.com/2022/03/27/cpp-coroutines-08-awaiter/)
* [渡劫 C++ 协程（9）：一个简单的示例](https://www.bennyhuo.com/2022/03/27/cpp-coroutines-09-http/)
* [渡劫 C++ 协程（10）：后记](https://www.bennyhuo.com/2022/03/27/cpp-coroutines-10-postscript/)

##  问题背景

我们前面在实现无阻塞 sleep 和 Channel 的时候都需要专门实现对应的 Awaiter 类型，并且在 TaskPromise 当中添加相应的 `await_transform` 函数。增加新类型这没什么问题，但如果每增加一个新功能就要对原有的 `TaskPromise` 类型做修改，这说明 `TaskPromise` 的扩展性不够好。



当然，有读者会说，如果我们把所有的 `await_transform` 函数都去掉，改成给对应的类型实现 `operator co_await` 来获取 Awaiter（例如 sleep 的例子当中通过 duration 转 Awaiter） 或者干脆就自己就定义成 Awaiter（例如 `Channel` 当中的 `ReadAwaiter` ），这样我们就不用总是修改 `TaskPromise` 了。话虽如此，但完全由外部定义 Awaiter 对象的获取会使得调度器无法被包装正确使用，甚至我们在定义 `TaskPromise` 的时候把调度器定义成私有成员，因为我们根本不希望外部能够轻易获取到调度器的实例。

使用 `await_transform` 本质上就是为了保证调度器的正确应用，却带来了扩展上的问题，那这是说 C++ 协程的设计有问题吗？当然也不是。我们完全可以定义一个 Awaiter 类型，外部只需要继承这个 Awaiter 在受限的范围内自定义逻辑，完成自己的需求同时也能保证调度器的调度。

##  通用的 await_transform

了解了需求背景之后，我们只需要在 `TaskPromise` 当中定义一个更加通用版本的 `await_transform` ，来为 Awaiter 提供调度器：

```cpp
template<typename ResultType, typename Executor>
struct TaskPromise {
  template<typename AwaiterImpl>
  AwaiterImpl await_transform(AwaiterImpl awaiter) {
    awaiter.install_executor(&executor);
    return awaiter;
  }
  ...
}
```


你看得没错，我们真的只是给这个通用的 `Awaiter` 添加了当前协程的调度器。

##  Awaiter 的定义

既然 `Awaiter` 的核心是调度器，我们可以直接给出它的基本定义：

```c++
template<typename R>
struct Awaiter {
  ...

  void install_executor(AbstractExecutor *executor) {
    _executor = executor;
  }

 private:
  AbstractExecutor *_executor = nullptr;
  ...

  
  void dispatch(std::function<void()> &&f) {
    if (_executor) {
      _executor->execute(std::move(f));
    } else {
      f();
    }
  }
}; 
```
作为 Awaiter 本身，当然也得有标准当中定义的基本的三个函数要求：

```c++
template<typename R>
struct Awaiter {

  
  bool await_ready() const { return false; }

  void await_suspend(std::coroutine_handle<> handle) {
    
    this->_handle = handle;
    ...
  }

  R await_resume() {
    ...
    
    return _result->get_or_throw();
  }
 protected:
  
  std::optional<Result<R>> _result{}; 

 private:
  AbstractExecutor *_executor = nullptr;
  
  std::coroutine_handle<> _handle = nullptr;
  ...
}
```
这几个函数是协程在挂起和恢复时调用的。我们将协程 `handle` 的保存和结果的返回逻辑固化，因为几乎所有的 Awaiter 都有这样的需求。不过协程的挂起后和恢复前是两个非常重要的时间点，扩展 Awaiter 时经常需要在这两个时间点实现定义化的业务逻辑，因此我们需要定义两个虚函数让子类按需实现：

```c++
template<typename R>
struct Awaiter {

  bool await_ready() const { return false; }

  void await_suspend(std::coroutine_handle<> handle) {
    this->_handle = handle;
    
    after_suspend();
  }

  R await_resume() {
    
    before_resume();
    return _result->get_or_throw();
  }
  ...

 protected:
  std::optional<Result<R>> _result{};

  virtual void after_suspend() {}

  virtual void before_resume() {}

  ...
}
```
剩下的就是协程的恢复了，这时候我们要求必须使用调度器进行调度。为了防止外部不按要求处理调度逻辑，我们将调度器和协程的 `handle` 都定义为私有成员，因此我们也需要提供相应的函数来封装协程恢复的逻辑：

```c++
template<typename R>
struct Awaiter {

  ...

  
  void resume(R value) {
    dispatch([this, value]() {
      
      _result = Result<R>(static_cast<R>(value));
      _handle.resume();
    });
  }

  
  
  void resume_unsafe() {
    dispatch([this]() { _handle.resume(); });
  }

  
  void resume_exception(std::exception_ptr &&e) {
    dispatch([this, e]() {
      _result = Result<R>(static_cast<std::exception_ptr>(e));
      _handle.resume();
    });
  }
  ...

}
```
这样一来，如果我们想要扩展新功能，只需要继承 `Awaiter` ，在 `after_suspend` 当中或者之后找个合适的时机调用 `resume/resume_unsafe/resume_exception` 三个函数当中的任意一个来恢复协程即可。如果在恢复前有其他逻辑需要处理，也可以覆写 `before_resume` 来实现。

##  Awaiter 的应用

接下来我们使用 `Awaiter` 对现有的几个 awaiter 类型做重构，之后再尝试基于 `Awaiter` 做一点小小的扩展。

###  重构 SleepAwaiter

`SleepAwaiter` 是最简单的一个。我们当初为了让无阻塞的 sleep 看上去更加自然，直接对 `duration` 做了支持，于是可以写出下面的代码：

```cpp
Task<void, LooperExecutor> task() {
  co_await 300ms;
  ...
} 
```
对 `duration` 的支持源自于在 `TaskPromise` 当中添加了 `duration` 转 `SleepAwaiter` 的 `awaiter_transform` 函数：

```cpp
template<typename _Rep, typename _Period>
SleepAwaiter await_transform(std::chrono::duration<_Rep, _Period> &&duration) {
  return SleepAwaiter(&executor, std::chrono::duration_cast<std::chrono::milliseconds>(duration).count());
}
```
如果不要求对 `duration` 直接支持的话，我们其实也可以这么设计：

```cpp
template<typename _Rep, typename _Period>
SleepAwaiter await_transform(SleepAwaiter awaiter) {
  
  awaiter._executor = &executor;
  return awaiter;
} 
```
这与我们前面给出的通用 `Awaiter` 版本的 `await_transform` 如出一辙：

```cpp
template<typename AwaiterImpl>
AwaiterImpl await_transform(AwaiterImpl awaiter) {
  
  awaiter.install_executor(&executor);
  return awaiter;
}
```
因此我们可以使用通用的 `Awaiter` 重构 `SleepAwaiter` ，下面我们给出重构前和重构后的对比：

**重构前**

```cpp
struct SleepAwaiter {

  explicit SleepAwaiter(AbstractExecutor *executor, long long duration) noexcept
      : _executor(executor), _duration(duration) {}

  bool await_ready() const { return false; }

  void await_suspend(std::coroutine_handle<> handle) const {
    static Scheduler scheduler;

    scheduler.execute([this, handle]() {
      _executor->execute([handle]() {
        handle.resume();
      });
    }, _duration);
  }

  void await_resume() {}

 private:
  AbstractExecutor *_executor;
  long long _duration;
}; 
```

**重构后**
```cpp
struct SleepAwaiter : Awaiter<void> {

  explicit SleepAwaiter(long long duration) noexcept
      : _duration(duration) {}

  
  template<typename _Rep, typename _Period>
  explicit SleepAwaiter(std::chrono::duration<_Rep, _Period> &&duration) noexcept
      : _duration(std::chrono::duration_cast<std::chrono::milliseconds>(duration).count()) {}

  void after_suspend() override {
    
    
    
    static Scheduler scheduler;
    scheduler.execute([this] { resume(); }, _duration);
  }

 private:
  long long _duration;
}; 
```
重构之后，我们无需单独为 `SleepAwaiter` 添加 `await_transform` 的支持，就可以写出下面的代码：

```cpp
Task<void, LooperExecutor> task()) {
    co_await SleepAwaiter(300ms);
  }
}
```
如果觉得不够美观，也可以定义一个协程版本的函数 sleep_for：

```cpp
template<typename _Rep, typename _Period>
SleepAwaiter sleep_for(std::chrono::duration<_Rep, _Period> &&duration) {
  return SleepAwaiter(duration);
} 
```
这样写出来的代码就变成了：

```cpp
Task<void, LooperExecutor> task()) {
    
    
    co_await sleep_for(300ms);
  }
}
```
###  重构 Channel 的 Awaiter

Channel 有两个 Awaiter，分别是 `ReaderAwaiter` 、 `WriterAwaiter` ，以前者为例：

**重构前**：

```cpp
template<typename ValueType>
struct ReaderAwaiter {
  Channel<ValueType> *channel;
  AbstractExecutor *executor = nullptr;
  ValueType _value;
  ValueType *p_value = nullptr;
  std::coroutine_handle<> handle;

  explicit ReaderAwaiter(Channel<ValueType> *channel) : channel(channel) {}

  ReaderAwaiter(ReaderAwaiter &&other) noexcept
      : channel(std::exchange(other.channel, nullptr)),
        executor(std::exchange(other.executor, nullptr)),
        _value(other._value),
        p_value(std::exchange(other.p_value, nullptr)),
        handle(other.handle) {}

  bool await_ready() { return false; }

  auto await_suspend(std::coroutine_handle<> coroutine_handle) {
    this->handle = coroutine_handle;
    channel->try_push_reader(this);
  }

  int await_resume() {
    channel->check_closed();
    channel = nullptr;
    return _value;
  }

  void resume(ValueType value) {
    this->_value = value;
    if (p_value) {
      *p_value = value;
    }
    resume();
  }

  void resume() {
    if (executor) {
      executor->execute([this]() { handle.resume(); });
    } else {
      handle.resume();
    }
  }

  ~ReaderAwaiter() {
    if (channel) channel->remove_reader(this);
  }
}; 
```
这代码大家已经见过，这里同样贴出来只是为了让大家能够直接对比：

**重构后**：

```cpp
template<typename ValueType>
struct ReaderAwaiter : public Awaiter<ValueType> {
  Channel<ValueType> *channel;
  ValueType *p_value = nullptr;

  explicit ReaderAwaiter(Channel<ValueType> *channel) : Awaiter<ValueType>(), channel(channel) {}

  ReaderAwaiter(ReaderAwaiter &&other) noexcept
      : Awaiter<ValueType>(other),
        channel(std::exchange(other.channel, nullptr)),
        p_value(std::exchange(other.p_value, nullptr)) {}

  void after_suspend() override {
    channel->try_push_reader(this);
  }

  void before_resume() override {
    channel->check_closed();
    if (p_value) {
      *p_value = this->_result->get_or_throw();
    }
    channel = nullptr;
  }

  ~ReaderAwaiter() {
    if (channel) channel->remove_reader(this);
  }
}; 
```
可以看到，调度的逻辑统一抽象到父类 `Awaiter` 当中，代码的逻辑更加紧凑了。不仅如此，之前在 `TaskPromise` 当中定义的 `await_transform` 也不需要了：


```cpp
template<typename _ValueType>
auto await_transform(ReaderAwaiter<_ValueType> reader_awaiter) {
  reader_awaiter.executor = &executor;
  return reader_awaiter;
}
```
`WriterAwaiter` 同理，不再赘述。

###  重构 TaskAwaiter

`TaskAwaiter` 是用来等待其他 `Task` 的执行完成的。它同样可以用前面的通用 `Awaiter` 改造：

**重构前**：

```cpp
template<typename Result, typename Executor>
struct TaskAwaiter {
  explicit TaskAwaiter(AbstractExecutor *executor, Task<Result, Executor> &&task) noexcept
      : _executor(executor), task(std::move(task)) {}

  TaskAwaiter(TaskAwaiter &&completion) noexcept
      : _executor(completion._executor), task(std::exchange(completion.task, {})) {}

  TaskAwaiter(TaskAwaiter &) = delete;

  TaskAwaiter &operator=(TaskAwaiter &) = delete;

  constexpr bool await_ready() const noexcept {
    return false;
  }

  void await_suspend(std::coroutine_handle<> handle) noexcept {
    task.finally([handle, this]() {
      _executor->execute([handle]() {
        handle.resume();
      });
    });
  }

  Result await_resume() noexcept {
    return task.get_result();
  }

 private:
  Task<Result, Executor> task;
  AbstractExecutor *_executor;

};
```
作为对比，重构后的代码同样变得简洁：

```cpp
template<typename R, typename Executor>
struct TaskAwaiter : public Awaiter<R> {
  explicit TaskAwaiter(Task<R, Executor> &&task) noexcept
      : task(std::move(task)) {}

  TaskAwaiter(TaskAwaiter &&awaiter) noexcept
      : Awaiter<R>(awaiter), task(std::move(awaiter.task)) {}

  TaskAwaiter(TaskAwaiter &) = delete;

  TaskAwaiter &operator=(TaskAwaiter &) = delete;

 protected:
  void after_suspend() override {
    task.finally([this]() {
      
      this->resume_unsafe();
    });
  }

  void before_resume() override {
    
    this->_result = Result(task.get_result());
  }

 private:
  Task<R, Executor> task;
}; 
```
改造完成之后，如果不希望为 `Task` 增加特权支持的话，之前对 `TaskAwaiter` 的 `await_transform` 同样可以删除掉：


```cpp
template<typename _ResultType, typename _Executor>
TaskAwaiter<_ResultType, _Executor> await_transform(Task<_ResultType, _Executor> &&task) {
  return TaskAwaiter<_ResultType, _Executor>(&executor, std::move(task));
}
```
然后为 `Task` 类型增加一个函数来获取 `TaskAwaiter` ：
```cpp
template<typename ResultType, typename Executor = NoopExecutor>
struct Task {

  auto as_awaiter() {
    return TaskAwaiter<ResultType, Executor>(std::move(*this));
  }
  ...
}
```
一旦调用 `as_awaiter` ，我们就会将 `Task` 的内容全部转移到新创建的 `TaskAwaiter` 当中，并且返回给外部使用：

```cpp
Task<int, LooperExecutor> simple_task() {
  
  
  auto result2 = co_await simple_task2().as_awaiter();
  ...
}
```
当然，在我们自己实现的这套 `Task` 框架当中， `Task` 自然是“特权阶层”，我们不会真的删除为 `Task` 定制的 `await_transform` 。但也不难看出，经过改造的 `Awaiter` 的子类代码量和复杂度都有降低；同时也不再需要定义专门的 `await_transform` 函数来明确支持 `TaskAwaiter` ，避免了扩展性不强的尴尬。

###  添加对 std::future 的扩展支持

按照 C++ 标准的发展趋势来看， `std::future` 应该在将来会支持类似于 `Task::then` 这样的函数回调，那时候我们完全不需要自己独立定义一套 `Task` ，只需要基于 `std::future` 进行扩展即可。

当然这都是后话了。现在 `std::future` 还不支持回调，我们可以另起一个线程来阻塞得等待它的结果，并在结果返回之后恢复协程的执行，这样一来，我们的 `Task` 框架也就能够支持形如 `co_await as_awaiter(future)` 这样的写法了。

想要做到这一点，我们只需要基于前面的 `Awaiter` 来依样画葫芦：

```cpp
template<typename R>
struct FutureAwaiter : public Awaiter<R> {
  explicit FutureAwaiter(std::future<R> &&future) noexcept
      : _future(std::move(future)) {}

  FutureAwaiter(FutureAwaiter &&awaiter) noexcept
      : Awaiter<R>(awaiter), _future(std::move(awaiter._future)) {}

  FutureAwaiter(FutureAwaiter &) = delete;

  FutureAwaiter &operator=(FutureAwaiter &) = delete;

 protected:
  void after_suspend() override {
    
    
    std::thread([this](){
      
      this->resume(this->_future.get());
    }).detach(); 
    
    
  }

 private:
  std::future<R> _future;
};
```
`FutureAwaiter` 与 `TaskAwaiter` 除了 `after_suspend` 和 `before_resume` 处有些不同之外，几乎完全一样（当然除了这俩函数以外也基本上没有其他逻辑了）。

如果你愿意，你也可以定义一个 `as_awaiter` 函数：

```cpp
template<typename R>
FutureAwaiter<R> as_awaiter(std::future<R> &&future) {
  return FutureAwaiter(std::move(future));
}
```
这样我们在协程当中就可以使用 `co_await` 来等待 `std::future` 的返回了：

```cpp
Task<void> task() {
  auto result = co_await as_awaiter(std::async([]() {
    std::this_thread::sleep_for(1s);
    return 1000;
  }));
  ...
}
```
##  AwaiterImpl 的类型约束

本文给出的通用的 `await_transform` 有个小小的漏洞，我们不妨再次观察一下这个函数的定义：

```cpp
template<typename AwaiterImpl>
AwaiterImpl await_transform(AwaiterImpl awaiter) {
  awaiter.install_executor(&executor);
  return awaiter;
}
```
不难发现，只要 `AwaiterImpl` 类型定义了协程的 `Awaiter` 类型的三个函数，并且定义有 `install_executor` 函数，在这里就可以蒙混过关，例如：

```cpp
struct FakeAwaiter {
  bool await_ready() { return false; }

  void await_suspend(std::coroutine_handle<> handle) {}

  void await_resume() {}

  void install_executor(AbstractExecutor *) {}
};

Task<void> task()) {

  co_await FakeAwaiter();

}
```
这个 `FakeAwaiter` 的定义符合前面的模板类型 `AwaiteImpl` 的要求，但却不符合我们的预期。为了避免这种情况发生，我们必须想办法要求 `AwaiterImpl` 只能是 `Awaiter` 或者它的子类。

这如果是在 Java 当中，我们可以很轻松地指定泛型的上界来达到目的。但 C++ 的模板显然与 Java 泛型的设计相差较大，不能直接在定义模板参数时指定上界。不过 C++ 20 的 concept 可以用来为模板参数限定父类。

我们需要定义一个用来检查类关系的 concept：
```cpp
template<typename AwaiterImpl, typename R>
concept AwaiterImplRestriction = std::is_base_of<Awaiter<R>, AwaiterImpl>::value; 
```
接下来我们只需要在 `await_transform` 的模板声明后面加上这个 concept 即可：

```cpp
template<typename AwaiterImpl>

requires AwaiterImplRestriction<AwaiterImpl, ???>
AwaiterImpl await_transform(AwaiterImpl awaiter) {  ...  }
```
不过这里有个问题，我们其实并不知道 `AwaiterImpl` 的实际类型在继承 `Awaiter` 时到底用了什么类型的模板参数，这怎么办呢？

有一个简单的办法，那就是为 `Awaiter` 声明一个内部类型 `ResultType` ：

```cpp
template<typename R>
struct Awaiter {

  using ResultType = R;

  ...
} 
```
这样我们就可以使用 `Awaiter::ResultType` 来获取这个类型：

```cpp
template<typename AwaiterImpl>
requires AwaiterImplRestriction<AwaiterImpl, typename AwaiterImpl::ResultType>
AwaiterImpl await_transform(AwaiterImpl awaiter) {
  ...
} 
```
这样像前面提到的 `FakeAwaiter` 那样的类型，就不能作为 `co_await` 表达式的参数了。即便我们为 `FakeAwaiter` 声明 `ResultType` 也不行， `co_await FakeAwaiter()` 的报错信息如下：

```
candidate template ignored: constraints not satisfied [with AwaiterImpl = FakeAwaiter] 
because 'AwaiterImplRestriction<FakeAwaiter, typename FakeAwaiter::ResultType>' evaluated to false 
because 'std::is_base_of<Awaiter<void>, FakeAwaiter>::value' evaluated to false call to 'await_transform' implicitly required by 'co_await' here
```
可见 `FakeAwaiter` 并不能满足与 `Awaiter` 的父子类关系，因此无法作为 `AwaiterImpl` 的模板实参。

##  小结

本文介绍了一种实现较为通用的 Awaiter 的方法，目的在于增加现有 `Task` 框架的扩展性，避免通过频繁改动 `TaskPromise` 来新增功能。

---

##  关于作者

**霍丙乾 bennyhuo**，Google 开发者专家（Kotlin 方向）； **《深入理解 Kotlin 协程》**作者（机械工业出版社，2020.6）； **《深入实践 Kotlin 元编程》**作者（机械工业出版社，2023.8）；前腾讯高级工程师，现就职于猿辅导

* GitHub： [https://github.com/bennyhuo](https://github.com/bennyhuo)
* 博客： [https://www.bennyhuo.com](https://www.bennyhuo.com/)
* bilibili： **[霍丙乾 bennyhuo](https://space.bilibili.com/28615855)**
* 微信公众号： **霍丙乾 bennyhuo**
