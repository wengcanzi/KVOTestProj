# KVOTestProj
Implement KVO again, adding block and target-action to callback.
根据系统KVO的实现原理，重写KVO功能，添加block和target-action的回调机制，有效防止部分crash的现象，已经过profile内存检测
基本原理：为被观察类动态创建一个新的类，将原来isa指针指向动态创建的新类，其调用setter时实际上执行的是新类中动态添加的setter方法，在方法中进行回调
