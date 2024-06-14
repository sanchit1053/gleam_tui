import gleam/erlang/process
import gleam/function
import gleam/io
import gleam/list
import gleam/string

const esc_code = "\u{001b}["

pub opaque type Application(state, message) {
  Application(
    state: state,
    render: fn(state) -> String,
    update: fn(state, message) -> #(state, Bool),
    events: List(fn() -> #(process.Subject(message), fn() -> Nil)),
    alt_screen: Bool,
  )
}

pub fn new_application(
  state: state,
  render: fn(state) -> String,
  update: fn(state, message) -> #(state, Bool),
  events: List(fn() -> #(process.Subject(message), fn() -> Nil)),
) -> Application(state, message) {
  Application(state, render, update, events, False)
}

pub fn on_alt_screen(
  appl: Application(state, message),
) -> Application(state, message) {
  Application(..appl, alt_screen: True)
}

fn clear_lines(num) {
  io.print(string.repeat(esc_code <> "2K" <> esc_code <> "1A", num))
  io.print("\r")
}

pub fn show(
  application: Application(state, message),
  state: state,
  previous_lines: Int,
) -> Int {
  clear_lines(previous_lines)
  let content = application.render(state)
  io.print(content)
  list.length(string.split(content, "\n"))
}

pub fn run(application: Application(state, message)) -> Nil {
  let subjects =
    application.events
    |> list.map(fn(t) { t() })

  case application.alt_screen {
    True -> io.print(esc_code <> "?1049h")
    False -> Nil
  }

  let selector = process.new_selector()

  let added_selector =
    subjects
    |> list.fold(selector, fn(sel, sub) {
      process.selecting(sel, sub.0, function.identity)
    })
  let cleanup =
    subjects
    |> list.map(fn(t) { t.1 })
  do_run(application, application.state, added_selector, cleanup, 1)
}

fn do_run(
  application: Application(a, b),
  state: a,
  selector: process.Selector(b),
  cleanup: List(fn() -> Nil),
  previous_lines: Int,
) -> Nil {
  let lines = show(application, state, previous_lines - 1)
  let msg = process.select_forever(selector)
  let #(new_state, running) = application.update(state, msg)
  case running {
    True -> do_run(application, new_state, selector, cleanup, lines)
    False -> {
      case application.alt_screen {
        True -> io.print(esc_code <> "?1049l")
        False -> Nil
      }
      cleanup
      |> list.map(fn(x) { x() })
      Nil
    }
  }
}
