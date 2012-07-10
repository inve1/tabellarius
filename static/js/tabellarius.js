renderMessage = function (el) {
  var $message, $tmp;
  $message = $('<div></div>').addClass('row-fluid');
  if (el.value.is_sent) {
    $tmp = $('<div></div>').addClass('span5');
    $message.append($tmp);
  }
  $tmp = $('<div></div>').addClass('span7 well').text(el.value.text);

  if (el.value.is_sent)
    $tmp.addClass('well-red');
  else $tmp.addClass('well-green');

  $message.append($tmp);
  return $message;
};

$('.user').live('click', function () {
  $.get('/messages/' + $(this).data('_id'))
    .done(function (data) {
      $('#messages').empty();
      var $data = $($.parseJSON(data)),
        $form;
      $data.each(function (i, el) {
        $message = renderMessage(el);
        $('#messages').append($message);
      });
      $form = $('<textarea></textarea>').data('_id', $data[0].key);
      $('#messages').append($form);
    })
    .fail(function () {
      console.log('non va');
    });
});

$('textarea').live('keyup', function (e) {
  if (e.which === 13) { // enter
    var json = {
      'text': $(this).val(),
      'number': $(this).data('_id')
    };
    window.socket.send(JSON.stringify(json));
    $(this).val('');
  }
});

function message (msg) {
  console.log(msg);
}

connectWebSocket = function () {
  try {
    var host = "ws://192.168.0.13:8080/";
    window.socket = new WebSocket(host);

    message('Socket Status: ' + socket.readyState);

    socket.onopen = function () {
      message('Socket Status: ' + socket.readyState + ' (open)');
    };

    socket.onmessage = function (msg) {
      var el = $.parseJSON(msg.data);
      $message = renderMessage(el);
      $($message).insertAfter('#messages div:last');
    };

    socket.onclose = function () {
      message('Socket Status: ' + socket.readyState + ' (Closed)');
    };

  } catch (exception) {
    message('<p>Error' + exception);
  }
};

initTabellarius = function () {
  $.get('/users/')
    .done(function (data) {
      var $data = $($.parseJSON(data))
        , $li;
      $data.each(function (i, el) {
        $li = $('<li></li>');
        $li
          .data('_id', el.key)
          .data('number', el.value['number'])
          .text(el.value['name'])
          .addClass('link')
          .addClass('user');
        $('#users-sidebar').append($li);
      });
    })
    .fail(function () {
      console.log('non va');
    });
};

$(document).ready(function () {
  if ("WebSocket" in window)
    connectWebSocket();
  initTabellarius();
});