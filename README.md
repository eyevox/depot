<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages). 
-->

Depot is a Dart actor model state management library intended for use with the Flutter apps.

Some of its inspirational sources are:

**MVVM** - Depot calls are a kind of bindings, with `command` and `request` being one-time bindings and `subscribe` as a
one-way binding. Two-way binding is not implemented though, because it restrains readability, and Depot is made to fight
complexity.

**RPC** - Depot calls are used as asynchronous functions, and may spread across address spaces, including isolates and
gateway services. The key difference is that `subscribe` returns asynchronous data stream, not a one value.

**DDD** - Depot modules are intended to hold the business entity models and domains, not a page models. Every module is
equally available from any point of your app, and can provide the same reactive state to different parts of it.

**Microservices** - Depot modules are self-sufficient entities to be reused through many apps, can be tested
independently, and have well-described facades with strong typing. This facades are hiding the implementations to make
changes and refactorings easy. It is not the real microservices, though, because their runtimes are not completely
isolated, and there are neither way, nor need for horizontal scaling in frontend.

**Smalltalk** - As the main course of computer science leaned from original Smalltalk objects to more Simula-like
objects in C++, some of the original ideas has been lost in translation. So, Depot introduces modules as smart
self-containing objects exchanging messages. Depot Modules, though, are not intended to have several exemplars - only to
contain them. Working with collections in Depot supposes storing them inside modules (allowing smart caches) and
addressing by indexes in calls.

## Features



## Getting started



## Usage


```

    Depot().localRegister<ExampleUserModuleFacade>(ExampleUserModuleFacade.new, ExampleUserModule());

    final nameStream = Depot<ExampleUserModuleFacade>().subscribe<String>().userNameStream();
    Depot<ExampleUserModuleFacade>().command().setUserName('Jane Doe');
    
```

## Additional information

This is a package in early stage of development, so feel free to contribute or request new features
