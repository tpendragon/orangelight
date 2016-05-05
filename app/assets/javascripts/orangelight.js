//= require 'jquery'

$(document).ready(function() {
    //link highlighting of subject heirarchy
    $(".search-subject").hover(
        function() {
            $(this).prevAll().addClass("subject-heirarchy");
        },
        function() {
            $(this).prevAll().removeClass("subject-heirarchy");
        }
    );

    //tooltip for facet remove button
    $(".facet-values").tooltip({
        selector: "[data-toggle='tooltip']",
        placement: "right",
        container: "body",
        trigger: "hover"
    });


    //tooltip for everything else
    $("#content").tooltip({
        selector: "[data-toggle='tooltip']",
        placement: "bottom",
        container: "body",
        trigger: "hover"
    });

    // availability toggle journal current issues
    $("#availability").on("click", ".trigger", function(event) {
        event.preventDefault();
        $(this).parent().siblings().toggleClass("all-issues");
        $(this).text(function(i, toggle) {
            return toggle === "More" ? "Less" : "More";
        });

    });

    ///////////////////////////////////////////
    // temporarily disable blacklight folders//
    //on change, submit form / add to folder //
    // $('#folder_id').change(function() {   //
    //     this.form.submit();               //
    // });                                   //
    ///////////////////////////////////////////

    //Select all items in specific account table to be checked or unchecked
    $("body").on("change", "[id^='select-all']", function (e) {
        if (this.checked) {
            $(this).closest("table").find("td input:checkbox").each(function(index) {
                $(this).prop("checked", true);
                $(this).closest("tr").toggleClass("info", this.checked);
            });
        } else {
            $(this).closest("table").find("td input:checkbox").each(function(index) {
                $(this).prop("checked", false);
                $(this).closest("tr").toggleClass("info", this.checked);
            });
        }
    });

    //Add active class to tr if selected
    $("body").on("change", "td input:checkbox", function(e) {
        $(this).closest("tr").toggleClass("info", this.checked);
    });

    // Auto dismiss alert-info and alert-success
    setTimeout(function() {
      $(".flash_messages .alert-info, .flash_messages .alert-success").fadeOut('slow', function(){
        $(".flash_messages .alert-info, .flash_messages .alert-success").remove();
      });
    }, 3000);
});
