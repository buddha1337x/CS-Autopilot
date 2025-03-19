$(document).ready(function () {
  // Listen for messages from the client.
  window.addEventListener('message', function (event) {
    const data = event.data;
    if (!data) return;
    
    if (data.action === "show") {
      // Set the CSS class for positioning from the config.
      $('#prompt').removeClass().addClass('notification ' + data.position);
      // Set the notification text.
      $('#prompt').text("Press [E] to engage autopilot");
      $('body').show();
    } else if (data.action === "hide") {
      $('body').hide();
    }
  });
});
