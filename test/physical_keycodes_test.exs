defmodule ElixirKeeb.PhysicalKeycodesTest do
  use ExUnit.Case

  defmodule GuineaPig do
    import ElixirKeeb.PhysicalKeycodes, only: [kc_xy?: 1]

    def is_it?(value) when kc_xy?(value), do: true

    def is_it?(_value), do: false
  end

  @subject ElixirKeeb.PhysicalKeycodes

  describe "is_kc_xy?/1" do
    test "it returns true when it should" do
      assert @subject.debug_all_keycodes
      |> Enum.map(&@subject.is_kc_xy?/1)
      |> Enum.all?()
    end

    test "it returns false when it should" do
      refute 0..1500
      |> Enum.map(&"yo#{&1}")
      |> Enum.map(&String.to_atom/1)
      |> Enum.map(&@subject.is_kc_xy?/1)
      |> Enum.all?()
    end
  end

  describe "kc_xy?/1 guard" do
    test "it returns true when it should" do
      assert @subject.debug_all_keycodes
      |> Enum.map(&GuineaPig.is_it?/1)
      |> Enum.all?()
    end

    test "it returns false when it should" do
      refute 0..1500
      |> Enum.map(&"yo#{&1}")
      |> Enum.map(&String.to_atom/1)
      |> Enum.map(&GuineaPig.is_it?/1)
      |> Enum.all?()
    end
  end
end
