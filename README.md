# gtui

[![Package Version](https://img.shields.io/hexpm/v/gtui)](https://hex.pm/packages/gtui)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gtui/)

This is inspired from TUI packages like [bubbleTea](https://github.com/charmbracelet/bubbletea)
## To Add
```sh
gleam add gtui
```

## Usage

```gleam
import gtui

fn main(){
    let state = State(...)
    let appl = gtui.new_application(state, render, update, events)
    gtui.run(appl)
}
```

## components 

#### State

```gleam
type State{
    State(...)
}
```
State is the information stored in the application, It can be store any type as needed  

#### Message

```gleam
type Message{
    MessageA,
    MessageB(Int)
}
```

These are all possible messages that the application needs to handle

#### Render

```gleam
fn render(state: State) -> String{
    ...
}
```

render function takes the state of the application and returns the String that will be shown on the screen,  
The package takes care of replacing the previous render

#### Update

```gleam
fn update(state: State, message: Message) -> #(State, Bool){
    ...
}
```

The function takes in a state and a message and returns the new state of the application and Bool denoting whether the Application keeps running or not

#### Events

Events are a list of functions that return a Subject from the `gleam_erlang` library and a clean up function

```gleam
fn event() -> #(process.Subject(Message), fn() -> Nil){
    ...
}

let Events = [event]
```

An Event is a function that will return a `process.Subject`, The intended use of this is to create a seperate process that will push messages onto the returned Subject,  
the package will poll the event and on recieving a message update the state of the application 

We will also return a cleanup function which will be run before the application closes to run any code to clean up the events


### Examples
Basic Examples of a infinite spinner and a list is available in the `examples` folder

----

Further documentation can be found at <https://hexdocs.pm/gtui>.
