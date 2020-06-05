defmodule OneSignal.Param do
	alias OneSignal.Param
	
	defstruct android_channel_id: nil,
			  messages: %{},
			  headings: nil,
			  included_segments: nil,
			  excluded_segments: nil,
			  include_external_user_ids: nil,
			  exclude_external_user_ids: nil,
			  include_player_ids: nil,
			  exclude_player_ids: nil,
			  include_ios_tokens: [],
			  include_android_reg_ids: [],
			  filters: [],
			  data: nil,
			  send_after: nil,
			  delayed_option: nil,
			  delivery_time_of_day: nil,
			  ttl: nil,
			  priority: 10,
			  apns_push_type_override: nil,
			  url: nil,
			  subtitle: nil,
			  content_available: true,
			  mutable_content: false,
			  template_id: nil,
			  big_picture: nil,
			  buttons: [],
			  ios_category: nil,
			  existing_android_channel_id: nil,
			  small_icon: nil,
			  large_icon: nil,
			  ios_sound: nil,
			  android_sound: nil,
			  android_led_color: nil,
			  android_accent_color: nil,
			  android_visibility: 1,
			  ios_badgeType: "SetTo",
			  ios_badgeCount: 0,
			  collapse_id: nil,
			  android_group: nil,
			  android_group_message: nil,
			  thread_id: nil,
			  summary_arg: nil,
			  summary_arg_count: nil,
			  isIos: nil,
			  isAndroid: nil,
			  apns_alert: %{},
			  android_background_layout: %{},
			  ios_attachments: %{}
	
	def to_string_key({k, v}) do
		{to_string(k), stringify_map(v)}
	end
	
	def stringify_map(m) do
		if is_map(m) do
			m
			|> Enum.map(&to_string_key/1)
			|> Enum.into(%{})
		else
			m
		end
	end
	
	@doc """
	Send push notification from parameters
	"""
	def notify(%Param{} = param) do
		param
		|> build
		|> OneSignal.Notification.send
	end
	
	@doc """
	Build notifications parameter of request
	"""
	def build(%Param{} = param) do
		required = %{
			"app_id" => OneSignal.fetch_app_id,
			"contents" => stringify_map(param.messages),
			"filters" => param.filters
		}
		
		reject_params = [
			:messages,
			:filters,
		]
		optionals = param
					|> Map.from_struct
					|> Enum.reject(
						   fn {k, v} ->
							   k in reject_params or is_nil(v)
						   end
					   )
					|> Enum.into(%{})
					|> stringify_map()

		Map.merge(required, optionals)
	end
	
	@doc """
	Put message in parameters
	
    iex> OneSignal.new
	     |> put_message(:en, "Hello")
	     |> put_message(:ja, "はろー")
	"""
	def put_message(%Param{} = param, message) do
		put_message(param, :en, message)
	end
	def put_message(%Param{} = param, language, message) do
		messages = Map.put(param.messages, language, message)
		%{param | messages: messages}
	end
	
	@doc """
	Put notification title.
	Notification title to send to Android, Amazon, Chrome apps, and Chrome Websites.
	
    iex> OneSignal.new
	      |> put_heading("App Notice!")
	      |> put_message("Hello")
	"""
	def put_heading(%Param{} = param, heading) do
		put_heading(param, :en, heading)
	end
	def put_heading(%Param{headings: nil} = param, language, heading) do
		%{
			param |
			headings: %{
				language => heading
			}
		}
	end
	def put_heading(%Param{headings: headings} = param, language, heading) do
		headings = Map.put(headings, language, heading)
		%{param | headings: headings}
	end
	
	@doc """
	Put specific target segment
	
    iex> OneSignal.new
	      |> put_message("Hello")
	      |> put_segment("Top-Rank")
	"""
	def put_segment(%Param{included_segments: nil} = param, segment) do
		%{param | included_segments: [segment]}
	end
	def put_segment(%Param{included_segments: seg} = param, segment) do
		%{param | included_segments: [segment | seg]}
	end
	
	@doc """
	Put specific filter
	
    iex> OneSignal.new
	      |> put_message("Hello")
	      |> put_filter("{userId: asdf}")
	"""
	def put_filter(%Param{filters: filters} = param, filter) do
		%{param | filters: [filter | filters]}
	end
	
	@doc """
	Put segments
	"""
	def put_segments(%Param{} = param, segs) do
		Enum.reduce(segs, param, fn next, acc -> put_segment(acc, next) end)
	end
	
	@doc """
	Drop specific target segment
	
    iex> OneSignal.new
	     |> put_segment("Free Players")
	     |> drop_segment("Free Players")
	"""
	def drop_segment(%Param{included_segments: nil} = param, _seg) do
		param
	end
	def drop_segment(%Param{} = param, seg) do
		segs = Enum.reject(param.included_segments, &(&1 == seg))
		%{param | included_segments: segs}
	end
	
	@doc """
	Drop specific target segments
	"""
	def drop_segments(%Param{} = param, segs) do
		Enum.reduce(segs, param, fn next, acc -> drop_segment(acc, next) end)
	end
	
	@doc """
	Exclude specific segment
	"""
	def exclude_segment(%Param{excluded_segments: nil} = param, seg) do
		%{param | excluded_segments: [seg]}
	end
	def exclude_segment(%Param{excluded_segments: segs} = param, seg) do
		%{param | excluded_segments: [seg | segs]}
	end
	
	@doc """
	Exclude segments
	"""
	def exclude_segments(%Param{} = param, segs) do
		Enum.reduce(segs, param, fn next, acc -> exclude_segment(acc, next) end)
	end
	
	@doc """
	Put external user id
	"""
	def put_external_user_id(%Param{include_external_user_ids: nil} = param, user_id) do
		%{param | include_external_user_ids: [user_id]}
	end
	def put_external_user_id(%Param{include_external_user_ids: ids} = param, user_id) do
		%{param | include_external_user_ids: [user_id | ids]}
	end
	
	def put_external_user_ids(%Param{} = param, user_ids) when is_list(user_ids) do
		Enum.reduce(
			user_ids,
			param,
			fn next, acc ->
				put_external_user_id(acc, next)
			end
		)
	end
	
	@doc """
	Exclude external user id
	"""
	def exclude_external_user_id(%Param{exclude_external_user_ids: nil} = param, user_id) do
		%{param | exclude_external_user_ids: [user_id]}
	end
	def exclude_external_user_id(%Param{exclude_external_user_ids: ids} = param, user_id) do
		%{param | exclude_external_user_ids: [user_id | ids]}
	end
	
	def exclude_external_user_ids(%Param{} = param, user_ids) when is_list(user_ids) do
		Enum.reduce(
			user_ids,
			param,
			fn next, acc ->
				exclude_external_user_id(acc, next)
			end
		)
	end
	
	@doc """
	Put player id
	"""
	def put_player_id(%Param{include_player_ids: nil} = param, player_id) do
		%{param | include_player_ids: [player_id]}
	end
	def put_player_id(%Param{include_player_ids: ids} = param, player_id) do
		%{param | include_player_ids: [player_id | ids]}
	end
	
	def put_player_ids(%Param{} = param, player_ids) when is_list(player_ids) do
		Enum.reduce(
			player_ids,
			param,
			fn next, acc ->
				put_player_id(acc, next)
			end
		)
	end
	
	@doc """
	Exclude player id
	"""
	def exclude_player_id(%Param{exclude_player_ids: nil} = param, player_id) do
		%{param | exclude_player_ids: [player_id]}
	end
	def exclude_player_id(%Param{exclude_player_ids: ids} = param, player_id) do
		%{param | exclude_player_ids: [player_id | ids]}
	end
	
	def exclude_player_ids(%Param{} = param, player_ids) when is_list(player_ids) do
		Enum.reduce(
			player_ids,
			param,
			fn next, acc ->
				exclude_player_id(acc, next)
			end
		)
	end
	
	@doc """
	Put data
	"""
	def put_data(%Param{data: nil} = param, key, value) do
		%{
			param |
			data: %{
				key => value
			}
		}
	end
	
	def put_data(%Param{data: data} = param, key, value) do
		%{param | data: Map.put(data, key, value)}
	end
	
	@doc """
	Set android channel/category for notification
	"""
	def set_android_channel_id(param, channel_id) do
		%{param | android_channel_id: channel_id}
	end
	
	@doc """
	Set destination URL.
	"""
	def put_url(param, nil), do: param
	def put_url(param, url) do
		%{param | url: url}
	end
	
	@doc """
	Set subtitle.
	"""
	def put_subtitle(param, nil), do: param
	def put_subtitle(param, subtitle) do
		%{param | subtitle: subtitle}
	end
	
	@doc """
	Put extend configurations.
	"""
	def put_extend(param, opts) do
		Map.merge(param, opts)
	end
	
	@doc """
	Put strict extend configurations.
	"""
	def put_strict(param, opts) do
		struct(param, opts)
	end
end
