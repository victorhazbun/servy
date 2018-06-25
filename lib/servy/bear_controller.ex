defmodule Servy.BearController do
  import Servy.View, only: [render: 3]
  alias Servy.Conv
  alias Servy.Wildthings
  alias Servy.Bear

  @templates_path Path.expand("../../templates", __DIR__)

  def index(conv) do
    bears =
      Wildthings.list_bears()
      |> Enum.sort(&Bear.order_asc_by_name/2)

    render(conv, "index.eex", bears: bears)
  end

  def show(conv, %{"id" => id}) do
    bear = Wildthings.get_bear(id)

    render(conv, "show.eex", bear: bear)
  end

  def create(conv, %{"name" => name, "type" => type} = _params) do
    %Conv{
      conv
      | status: 201,
        resp_body: "Created a #{name} bear named #{type}!"
    }
  end

  def delete(conv, _params) do
    %Conv{conv | status: 403, resp_body: "Deleting a bear is forbidden!"}
  end
end
