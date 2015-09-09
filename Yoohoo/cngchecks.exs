defmodule CngChecks do

  defp start_inets() do
      case :inets.start() do
        :ok -> false
        _ -> true
      end
  end

  defp start_ssl() do
      case :ssl.start() do
        :ok -> false
        _ -> true
      end
  end

  defp stop_inets() do
      case :inets.stop() do
        :ok -> false
        _ -> true
      end
  end
  
  defp stop_ssl() do
      case :ssl.stop() do
        :ok -> false
        _ -> true
      end
  end
    
  def package_exists?(package_to_check) do
    inet_was_started = start_inets()
    ssl_was_started = start_ssl()
    {:ok,result} = :httpc.request(:get, {String.to_char_list(package_to_check), []}, [], [])
    pkg_exists =
       case elem(result,0) do
         {_, 200, _} -> true
         {_, 404, _} -> false
       end
    if not inet_was_started, do: stop_inets()
    if not ssl_was_started, do: stop_ssl()
    pkg_exists
  end
end
