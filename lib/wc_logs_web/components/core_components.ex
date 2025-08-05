defmodule WcLogsWeb.CoreComponents do
  use Phoenix.Component

  attr :class, :string, default: nil

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@class]} />
    """
  end
end