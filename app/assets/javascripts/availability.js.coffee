jQuery ->
  window.availability_updater = new AvailabilityUpdater
class AvailabilityUpdater
  constructor: ->
    this.request_availability()
  availability_url: "http://bibdata.princeton.edu/availability"
  request_availability: ->
    ids = this.record_ids().toArray()
    params = $.param({ids: ids})
    url = "#{@availability_url}?#{params}"
    $.getJSON(url, this.process_records)
  process_records: (records) =>
    for record_id, availability_info of records
      this.apply_record(record_id, availability_info)
  apply_record: (record_id, availability_info) ->
    if availability_info.more_holdings == true
      this.record_needs_more_info(record_id)
    else
      for location_code, status of availability_info
        this.apply_record_icon(record_id, location_code, status)
    true
  record_needs_more_info: (record_id) ->
    element = $("*[data-record-id='#{record_id}'] .availability-icon")
    element.addClass("glyphicon glyphicon-info-sign")
    element.prop('title', "Click on the record for full availability info")
  apply_record_icon: (record_id, location_code, status) ->
     availability_element = $("*[data-record-id='#{record_id}'][data-loc-code='#{location_code}'] .availability-icon")
     availability_element.addClass("glyphicon")
     if status == "Not Charged"
       availability_element.addClass("glyphicon-ok text-success")
     else
       availability_element.addClass("glyphicon-remove text-danger")
     availability_element.prop('title', status)
  record_ids: ->
    $("*[data-availability-record][data-record-id]").map((_, x) -> $(x).attr("data-record-id"))