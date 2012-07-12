renderMessage = function (el) {
  var $message, $tmp;
  $message = $('<div></div>').addClass('row-fluid');
  if (el.value.is_sent) { //add space on the left
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

renderUser = function (el) {
  var $li = $('<li></li>');
  $li
    .data('_id', el.key)
    .data('number', el.value['number'])
    .text(el.value['name'])
    .addClass('link')
    .addClass('user');
  return $li;
};

$('.user').live('click', function () {
  var $this = $(this);
  $this.css('background','');
  $('#conversation-header').show().data('_id', $this.data('_id'));
  $('#conversation-name').text($this.text());
  $('#conversation-number').text("(" + $this.data('number') + ")");
  $.get('/messages/' + $(this).data('_id'))
    .done(function (data) {
      $('#messages').empty();
      var $data = $($.parseJSON(data)),
        $form;
      $data.each(function (i, el) {
        $message = renderMessage(el);
        $('#messages').append($message);
      });
      $form = $('<textarea></textarea>').data('_id', $this.data('_id'));
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

$('#new-user-number').live('keyup', function (e) {
  if (e.which === 13)
    $('#add-users-confirm-button').click();
});

$('#add-users-confirm-button').live('click', function () {
  var $newUserName = $('#new-user-name')
    , $newUserNumber = $('#new-user-number');
  $.post('/users/' + $newUserName.val() + '/' + $newUserNumber.val() + '/')
    .fail(function () {
      console.log('non va');
    });
  $newUserName.val('');
  $newUserNumber.val('');
});

function message (msg) {
  console.log(msg);
}

connectWebSocket = function () {
  var $user, $message;
  try {
    var host = "ws://i1.m-2.it:8080/";
    window.socket = new WebSocket(host);

    message('Socket Status: ' + socket.readyState);

    socket.onopen = function () {
      message('Socket Status: ' + socket.readyState + ' (open)');
    };

    socket.onmessage = function (msg) {
      var el = $.parseJSON(msg.data);
      if (el.user !== undefined) { //user
        $user = renderUser(el.user);
        $($user).insertAfter('#users-sidebar li:last');
      }
      else if (el.message !== undefined) {
        $message = renderMessage(el.message);
        if (el.message.value.fromto == $('#conversation-header').data('_id'))
          if ($('#messages div').length === 0)
            $($message).insertBefore('#messages textarea');
          else $($message).insertAfter('#messages div:last');
        else {
          $('#users-sidebar li').each(function(){
            if(el.message.value.fromto == $(this).data('_id'))
              $(this).css('background','#EDEDED')
          })
        }
      }
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
        $li = renderUser(el);
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
