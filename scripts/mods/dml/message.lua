local chat_sound = "wwise/events/ui/play_ui_click"

local notify = function(message)
  local event_manager = Managers and Managers.event

  if event_manager then
    event_manager:trigger("event_add_notification_message", "default", message, nil, chat_sound)
  end

  print(message)
end

local echo = function(message, sender)
  local chat_manager = Managers and Managers.chat
  local event_manager = Managers and Managers.event

  if chat_manager and event_manager then
    local message_obj = {
      message_body = message,
      is_current_user = false,
    }

    local participant = {
      displayname = sender or "SYSTEM",
    }

    local message_sent = false

    local channel_handle, channel = next(chat_manager:connected_chat_channels())
    if channel then
      event_manager:trigger("chat_manager_message_recieved", channel_handle, participant, message_obj)
      message_sent = true
    end

    if not message_sent then
      notify(message)
      return
    end
  end

  print(message)
end

Mods.message = {
    echo = echo,
    notify = notify,
}
