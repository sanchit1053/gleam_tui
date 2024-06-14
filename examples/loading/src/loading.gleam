import gleam/erlang/process
import gleam/option
import gleam/otp/actor
import glerm
import gtui

type State =
  Int

type Message {
  GlermEvent(glerm.Event)
  TimerEvent
}

pub fn main() {
  let state = 0
  let appl = gtui.new_application(state, render, update, [check_key, timer])
  gtui.run(appl)
}

fn render(state: State) -> String {
  let spinner = fn(st) {
    case st {
      0 -> "|"
      1 -> "/"
      2 -> "-"
      3 -> "\\"
      _ -> panic
    }
  }

  "\r\n " <> spinner(state) <> " infinite spinner \r\n" <> " Press q to close\r\n"
}

fn update(state: State, msg: Message) -> #(State, Bool) {
  case msg {
    GlermEvent(glerm.Key(glerm.Character("c"), option.Some(glerm.Control))) -> {
      #(state, False)
    }
    GlermEvent(glerm.Key(glerm.Character("q"), _)) -> {
      #(state, False)
    }
    TimerEvent -> {
      #({ state + 1 } % 4, True)
    }
    _ -> #(state, True)
  }
}

fn check_key() -> #(process.Subject(Message), fn() -> Nil) {
  let glerm_events = process.new_subject()
  let assert Ok(_) = glerm.enable_raw_mode()
  let assert Ok(_) =
    glerm.start_listener(0, fn(event, state) {
      process.send(glerm_events, GlermEvent(event))
      actor.continue(state)
    })
  #(glerm_events, fn() {
    let assert Ok(_) = glerm.disable_raw_mode()
    Nil
  })
}

fn timer_function(subject) {
  fn() -> Nil {
    process.sleep(100)
    process.send(subject, TimerEvent)
    timer_function(subject)()
    Nil
  }
}

fn timer() -> #(process.Subject(Message), fn() -> Nil) {
  let timer_events = process.new_subject()
  process.start(timer_function(timer_events), True)
  #(timer_events, fn() { Nil })
}
