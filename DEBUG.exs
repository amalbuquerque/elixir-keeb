# 2020/03/21 11:40:05
# Redid the circuit twice and B4 continues to not work
# on the Canon Typewriter "PCB"
b_pins = [
  {:BA, 4},
  {:B9, 17},
  {:B8, 27},
  {:B7, 22},
  {:B6, 10},
  {:B5, 9},
  {:B4, 11},
  {:B3, 5},
  {:B2, 6},
  {:B1, 13}
]

a_pins = [
  {:AB, 14},
  {:AA, 15},
  {:A9, 18},
  {:A8, 23},
  {:A7, 24},
  {:A6, 25},
  {:A5, 8},
  {:A4, 7},
  {:A3, 12},
  {:A2, 16},
  {:A1, 20}
]

open_ports = fn (pins, direction) when direction in [:input, :output] ->
  pins
  |> Enum.map(fn {matrix_port, pin} ->
    {:ok, gpio} = Circuits.GPIO.open(pin, direction)

    Circuits.GPIO.set_pull_mode(gpio, :pulldown)

    {matrix_port, gpio}
  end)
  |> Enum.into(%{})
end

require Logger
alias ElixirKeeb.Gpio

spawn(fn ->
  ports_a = Gpio.open_ports.(a_pins, :output)
  ports_b = Gpio.open_ports.(b_pins, :input)

  for {a_port, a_gpio} <- ports_a do
    Circuits.GPIO.write(a_gpio, 1)

    for {b_port, b_gpio} <- ports_b do
      Circuits.GPIO.read(b_gpio)
      |> case do
        1 -> Logger.info("Pressed #{a_port} + #{b_port}!")
        _ -> :noop
      end
      Process.sleep(10)
    end

    Circuits.GPIO.write(a_gpio, 0)
  end
end)
