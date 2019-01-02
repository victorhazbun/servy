defmodule HttpServerTest do
	use ExUnit.Case

	alias Servy.HttpServer

	test "accepts a request on a socket and sends back a response" do
		spawn(HttpServer, :start, [4000])

		{:ok, response} = HTTPoison.get "http://localhost:4000/wildthings"

		assert response.status_code == 200
		assert response.body == "Bears, Lions, Tigers"
	end
end