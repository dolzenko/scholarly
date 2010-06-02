$(function() {
  $(".report_part").each(function() {
    var h2 = $(this).find("h2");
    var content = $(this).find("div:first");
    h2.click(function() {
      content.toggle();
    });
  });
});