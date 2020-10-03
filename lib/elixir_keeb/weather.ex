defmodule ElixirKeeb.Weather do
  require Logger
  alias HTTPoison.Response, as: HttpResponse

  @api_key System.get_env("WEATHER_API_KEY")

  def city_weather(city) do
    url = url(city)


    Logger.debug("Hitting #{url}")

    HTTPoison.get!(url)
    |> format_response()
  end

  def format_response(raw_response) do
    case raw_response do
      %HttpResponse{status_code: 200, body: body} ->
        response = Jason.decode!(body)

        city = response["name"]

        temp = response["main"]["temp"]
        humidity = response["main"]["humidity"]

        weather = response
                  |> Map.get("weather")
                  |> Enum.at(0)

        description = weather["description"]

        "#{String.capitalize(description)} in #{city}. Temperature: #{temp} C, humidity: #{humidity}%"

      %HttpResponse{status_code: 404} ->
        "City not found"

      _ ->
        raw_response
    end
  end

  def url(city) do
    "https://api.openweathermap.org/data/2.5/weather?q=#{city}&units=metric&appid=#{@api_key}"
  end
end
