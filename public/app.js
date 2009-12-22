$(document).ready(function() {
        $("#datepicker").datepicker();
});
function mark_as_done($id) {
       $.post("/done", {id: $id}, function(data) {$("#"+$id).hide();});
}
