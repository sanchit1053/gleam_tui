import gleam/erlang/process
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/result
import glerm
import gtui

type State {
  State(options: List(String), choice: Int, chosen: Option(Int))
}

type Message {
  GlermEvent(glerm.Event)
}

pub fn main() {
  let state =
    State(
      options: ["make application", "buy milk", "walk the dog"],
      choice: 0,
      chosen: None,
    )
  let appl =
    gtui.new_application(state, render, update, [check_key])
    |> gtui.on_alt_screen
  gtui.run(appl)
}

fn render(state: State) -> String {
  let len = list.length(state.options)

  let show = fn(it: #(String, Int)) {
    case it.1 == state.choice {
      True -> " > "
      False -> "   "
    }
    <> it.0
    <> "\r\n"
  }

  let get_element_at = fn(items: List(String), index: Int) -> String {
    items
    |> list.zip(list.range(0, len))
    |> list.find(fn(a) { a.1 == index })
    |> result.map(fn(item) { item.0 })
    |> result.unwrap("")
  }

  let selected_item = case state.chosen {
    None -> " No Item Selected"
    Some(a) -> " Selected Item : " <> get_element_at(state.options, a)
  }

  "LIST EXAMPLE "
  <> "\r\n"
  <> state.options
  |> list.zip(list.range(0, len))
  |> list.map(show)
  |> list.fold("", fn(a, e) { a <> e })
  <> "\r\n"
  <> selected_item
  <> "\r\n"
  <> "\r\n press q to quit"
}

fn update(state: State, msg: Message) -> #(State, Bool) {
  case msg {
    GlermEvent(glerm.Key(glerm.Character("c"), option.Some(glerm.Control)))
    | GlermEvent(glerm.Key(glerm.Character("q"), _)) -> {
      #(state, False)
    }
    GlermEvent(glerm.Key(glerm.Enter, _)) -> {
      #(State(..state, chosen: Some(state.choice)), True)
    }
    GlermEvent(glerm.Key(glerm.Up, _)) -> {
      #(State(..state, choice: int.max(0, state.choice - 1)), True)
    }
    GlermEvent(glerm.Key(glerm.Down, _)) -> {
      #(
        State(
          ..state,
          choice: int.min(list.length(state.options) - 1, state.choice + 1),
        ),
        True,
      )
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
