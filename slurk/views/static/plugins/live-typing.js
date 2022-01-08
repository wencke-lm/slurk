let old_value = "";
let typed_messages = {};


$(document).ready(() => {
    function liveTyping(data) {
        if (self_user === undefined || data.user.id === self_user.id) {
            return
        }

        let scrollbar_at_bottom = false;
        let content = $('#content');
        if (content.prop("scrollTop") + content.prop("clientHeight") + 20 >= content.prop("scrollHeight")) {
            scrollbar_at_bottom = true;
        }

        if (data.text == "") {
            delete typed_messages[data.user.name];
        } else {
            typed_messages[data.user.name] = data.text;
        }

        $("#typing").empty();
        for (let user_name in typed_messages) {
            let bubble = $(
            "<li class='other'>" +
            "  <div class='message-box'>" +
            "    <div class='dot-flashing'></div>" +
            "    <span class='message'>" + user_name + "</span>" +
                "    <div>" + typed_messages[user_name] + "</div>" +  
            "  </div>" +
            "</li>");
            $("#typing").append(bubble);
        }
        // only scroll down, if user not looking through older history
        if (scrollbar_at_bottom) {
            content.animate({ scrollTop: content.prop("scrollHeight") }, 0);
        }
    }

    socket.on("typed_message", liveTyping);

    $("#text").on("keypress", function submitMessage(event) {
        let code = event.keyCode || event.which;
        if (code === 13) {
            old_value = "";
            socket.emit("typed_message", {
                "text": old_value
            });
        }
    });

    socket.on("stop_typing", function removePreview(data) {
        if (self_user === undefined || data.user.id === self_user.id) {
            return;
        }
        data["text"] = "";
        liveTyping(data);
    });

    // at some point the user should submit the message
    // in order not to encourage them to communicate only
    // via the message preview, deleting and changing messages is disabled
    $("#text").on("input", function updateText() {
        let new_value = $("#text").val();
        if (old_value.length >= new_value.length) {
            $("#text").val(old_value);
            alert("You can neither delete nor replace typed characters.")
        } else {
            old_value = new_value;
            socket.emit("typed_message", {
                "text": old_value
            });
        }
    });
});
