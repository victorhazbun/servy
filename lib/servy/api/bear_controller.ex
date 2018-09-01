defmodule Servy.Api.BearController do
  
  alias Servy.Conv
  
  def index(conv) do
    json =
      Servy.Wildthings.list_bears()
      |> Poison.encode!

    conv = put_resp_content_type(conv, "application/json")
    
    %Conv{ conv | status: 200, resp_body: json }
  end

  def put_resp_content_type(conv, type) do
		headers = Map.put(conv.resp_headers, "Content-Type", type)
		%Conv{ conv | resp_headers: headers }
  end
end
