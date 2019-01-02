defmodule Servy.Handler do

  @moduledoc "Handles HTTP requests."

  alias Servy.Conv
  alias Servy.BearController
  alias Servy.VideoCam
    
  @pages_path Path.expand("pages", File.cwd!())

  import Servy.Plugins, only: [rewrite_path: 1, log: 1, track: 1]
  import Servy.Parser, only: [parse: 1]
  import Servy.FileHandler, only: [handle_file: 2]

  @doc "Transforms the request into a response."
  def handle(request) do
    request 
    |> parse
    |> rewrite_path
    |> log 
    |> route 
    |> track
    |> put_content_length
    |> format_response
  end

  def route(%Conv{ method: "GET", path: "/snapshots"} = conv) do
    parent = self() # This is the request-handing process
    
    spawn(fn -> send(parent, {:result, VideoCam.get_snapshot("cam-1")}) end)
    spawn(fn -> send(parent, {:result, VideoCam.get_snapshot("cam-2")}) end)
    spawn(fn -> send(parent, {:result, VideoCam.get_snapshot("cam-3")}) end)
    
    snapshot1 = receive do {:result, filename} -> filename end
    snapshot2 = receive do {:result, filename} -> filename end
    snapshot3 = receive do {:result, filename} -> filename end

    snapshots = [snapshot1, snapshot2, snapshot3]

    %{ conv | status: 200, resp_body: inspect snapshots }
  end

  def route(%Conv{ method: "GET", path: "/kaboom" }) do
    raise "Kaboom!"
  end

  def route(%Conv{ method: "GET", path: "/hibernate/" <> time } = conv) do
    time |> String.to_integer |> :timer.sleep
    
    %{ conv | status: 200, resp_body: "Awake!" }          
  end

  def route(%Conv{ method: "GET", path: "/wildthings" } = conv) do
    %{ conv | status: 200, resp_body: "Bears, Lions, Tigers" }          
  end

  def route(%Conv{ method: "GET", path: "/api/bears" } = conv) do
    Servy.Api.BearController.index(conv)
  end

  def route(%Conv{ method: "POST", path: "/api/bears" } = conv) do
    Servy.Api.BearController.create(conv, conv.params)
  end

  def route(%Conv{ method: "GET", path: "/bears" } = conv) do
    BearController.index(conv)
  end

  def route(%Conv{ method: "GET", path: "/bears/" <> id } = conv) do
    params = Map.put(conv.params, "id", id)
    BearController.show(conv, params)
  end

  def route(%Conv{method: "POST", path: "/bears"} = conv) do
    BearController.create(conv, conv.params)
  end

  def route(%Conv{method: "DELETE", path: "/bears/" <> _id} = conv) do
    BearController.delete(conv, conv.params)
  end

  def route(%Conv{method: "GET", path: "/pages/" <> name} = conv) do
    @pages_path
    |> Path.join("#{name}.md")
    |> File.read
    |> handle_file(conv)
    |> markdown_to_html
  end

  def route(%Conv{ path: path } = conv) do
    %{ conv | status: 404, resp_body: "No #{path} here!"}
  end

  def format_response(%Conv{} = conv) do
    """
    HTTP/1.1 #{Conv.full_status(conv)}\r
    #{format_response_headers(conv)}
    \r
    #{conv.resp_body}
    """
  end

  def put_content_length(conv) do
    headers = Map.put(conv.resp_headers, "Content-Length", String.length(conv.resp_body))
    %{ conv | resp_headers: headers }
  end

  defp format_response_headers(conv) do
    Enum.map(conv.resp_headers, fn {key, value} ->
      "#{key}: #{value}\r"
    end) |> Enum.sort |> Enum.reverse |> Enum.join("\n")
  end

  def markdown_to_html(%Conv{status: 200} = conv) do
    %{ conv | resp_body: Earmark.as_html!(conv.resp_body) }
  end

  def markdown_to_html(%Conv{} = conv), do: conv

end

