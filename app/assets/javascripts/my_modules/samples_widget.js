//= require datatables

table = $("#samples").DataTable({
    order: [[2, "desc"]],
    dom: "RB<'row'<'col-sm-9-custom toolbar'l><'col-sm-3-custom'>>",
    stateSave: false,
    bPaginate: false,
    buttons: [],
    processing: false,
    serverSide: true,
    ajax: {
        url: $("#samples").data("source"),
        global: false,
        type: "POST"
    },
    colReorder: {
        fixedColumnsLeft: 1000000 // Disable reordering
    },
    columns: (function() {
        var numOfColumns = $("#samples").data("num-columns");
        var columns = [];

        for (var i = 0; i < numOfColumns; i++) {
            var visible = (i > 0 && i <= 6);
            columns.push({
                data: i + "",
                defaultContent: "",
                visible: visible
            });
        }
        return columns;
    })(),
    fnDrawCallback: function(settings, json) {
        animateSpinner(this, false);
    },
    preDrawCallback: function(settings) {
        animateSpinner(this);
        $(".sample_info").off("click");
    }
});
