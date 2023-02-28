/* global TinyMCE I18n animateSpinner importProtocolFromFile */
/* global HelperModule DataTableHelpers GLOBAL_CONSTANTS */
/* eslint-disable no-use-before-define, no-alert, no-restricted-globals, no-underscore-dangle */

//= require my_modules
//= require protocols/import_export/import

// Currently selected row in "load from protocol" modal
var selectedRow = null;


function initEditMyModuleDescription() {
  var viewObject = $('#my_module_description_view');
  viewObject.on('click', function(e) {
    if ($(e.target).hasClass('record-info-link')) return;
    TinyMCE.init('#my_module_description_textarea');
  }).on('click', 'a', function(e) {
    if ($(this).hasClass('record-info-link')) return;
    e.stopPropagation();
  });

  setTimeout(function() {
    TinyMCE.wrapTables(viewObject);
  }, 100);
}

function initEditProtocolDescription() {
  var viewObject = $('#protocol_description_view');
  viewObject.on('click', function(e) {
    if ($(e.target).hasClass('record-info-link')) return;
    TinyMCE.init('#protocol_description_textarea', { afterInitCallback: refreshProtocolStatusBar });
  }).on('click', 'a', function(e) {
    if ($(this).hasClass('record-info-link')) return;
    e.stopPropagation();
  });
}

function initCopyToRepository() {
  var link = "[data-action='copy-to-repository']";
  var modal = '#copy-to-repository-modal';
  var modalBody = '.modal-body';
  var submitBtn = ".modal-footer [data-action='submit']";
  $('.my-modules-protocols-index')
    .on('ajax:success', link, function(e, data) {
      $(modal).find(modalBody).html(data.html);
      $(modal).find(modalBody).find("[data-role='copy-to-repository']")
        .on('ajax:success', function(e2, data2) {
          if (data2.refresh !== null) {
            // Reload page
            location.reload();
          } else {
            // Simply hide the modal
            $(modal).modal('hide');
          }
        })
        .on('ajax:error', function(e2, data2) {
          // Display errors in form
          $(modal).find(submitBtn)[0].disabled = false;
          if (data2.status === 422) {
            $(this).renderFormErrors('protocol', data2.responseJSON);
          } else {
            // Simply display global error
            alert(data2.responseJSON.message);
          }
        });

      $(modal).modal('show');
      $(modal).find(submitBtn)[0].disabled = false;
    })
    .on('ajax:error', function() {});

  $(modal).on('click', submitBtn, function() {
    // Submit the embedded form
    $(modal).find(submitBtn)[0].disabled = true;
    $(modal).find('form').submit();
  });

  $(modal).find(modalBody).on('click', "[data-role='link-check']", function() {
    var text = $(this).closest('.modal-body').find("[data-role='link-text']");
    if ($(this).prop('checked')) {
      text.show();
    } else {
      text.hide();
    }
  });

  $(modal).on('hidden.bs.modal', function() {
    $(modal).find(modalBody).find("[data-role='copy-to-repository']")
      .off('ajax:success ajax:error');

    $(modal).find(modalBody).html('');
  });
}

function initLinkUpdate() {
  var modal = $('#confirm-link-update-modal');
  var modalTitle = modal.find('.modal-title');
  var modalBody = modal.find('.modal-body');
  var updateBtn = modal.find(".modal-footer [data-action='submit']");
  $("[data-action='unlink'], [data-action='revert'], [data-action='update-parent'], [data-action='update-self']")
    .on('ajax:success', function(e, data) {
      const {
        title,
        message,
        btn_text: btnText,
        url
      } = data;

      modalTitle.html(title);
      modalBody.html(message);
      updateBtn.text(btnText);
      modal.attr('data-url', url);
      modal.modal('show');
    });

  modal.on('hidden.bs.modal', function() {
    modalBody.html('');
  });

  if (!$._data(updateBtn[0], 'events')) {
    updateBtn.on('click', function() {
      // POST via ajax
      $.ajax({
        url: modal.attr('data-url'),
        type: 'POST',
        dataType: 'json',
        success: function() {
          // Simply reload page
          location.reload();
        },
        error: function(ev) {
          // Display error message in alert()
          alert(ev.responseJSON.message);

          // Hide modal
          modal.modal('hide');
        }
      });
    });
  }

  $('[data-role="protocol-status-bar"] .preview-protocol').click(function(e) {
    e.preventDefault();
  });
}

function initLoadFromRepository() {
  var modal = $('#load-from-repository-modal');
  var modalBody = modal.find('.modal-body');
  var loadBtn = modal.find(".modal-footer [data-action='submit']");

  $("[data-action='load-from-repository']")
    .on('ajax:success', function(e, data) {
      modalBody.html(data.html);

      // Disable load btn
      loadBtn.attr('disabled', 'disabled');

      modal.modal('show');

      // Init Datatable on recent tab
      initLoadFromRepositoryTable(modalBody.find('#load-protocols-datatable'));

      loadBtn.on('click', function() {
        loadFromRepository();
      });
    });
  modal.on('hidden.bs.modal', function() {
    // Destroy the current Datatable
    destroyLoadFromRepositoryTable(modalBody.find('#load-protocols-datatable'));
    loadBtn.off('click');
    modalBody.html('');
  });
}

function initLoadFromRepositoryTable(content) {
  var tableEl = content.find("[data-role='datatable']");
  var datatable = tableEl.DataTable({
    dom: "R<'main-actions'<'toolbar'><'protocol-filters'f>>t"
      + "<'pagination-row'<'pagination-info'li><'pagination-actions'p>>",
    sScrollX: '100%',
    sScrollXInner: '100%',
    buttons: [],
    processing: true,
    serverSide: true,
    responsive: true,
    order: [[5, 'desc']],
    ajax: {
      url: tableEl.data('source'),
      type: 'POST'
    },
    colReorder: {
      fixedColumnsLeft: 1000000 // Disable reordering
    },
    columnDefs: [{
      targets: [0, 3, 4],
      searchable: true,
      orderable: true
    }, {
      targets: [1, 2, 5],
      searchable: true,
      orderable: true,
      render: function(data) {
        return `<div class="nowrap">${data}</div`;
      }
    }],
    columns: [
      { data: '0' },
      { data: '1' },
      { data: '2' },
      { data: '3' },
      { data: '4' },
      { data: '5' }
    ],
    oLanguage: {
      sSearch: I18n.t('general.filter')
    },
    rowCallback: function(row, data) {
      // Get row ID
      var rowId = data.DT_RowId;
      $(row).attr('data-row-id', rowId);
    },
    fnDrawCallback: function() {
      animateSpinner(this, false);
    },
    preDrawCallback: function() {
      animateSpinner(this);
    },
    fnInitComplete: function(e) {
      var dataTableWrapper = $(e.nTableWrapper);
      DataTableHelpers.initLengthAppearance(dataTableWrapper);
      DataTableHelpers.initSearchField(
        dataTableWrapper,
        I18n.t('my_modules.protocols.load_from_repository_modal.filter_protocols')
      );

      $('.toolbar').html(I18n.t('my_modules.protocols.load_from_repository_modal.text2'));
    }
  });

  // Handle clicks on row
  tableEl.find('tbody').on('click', 'tr', function(e) {
    // Uncheck all
    tableEl.find('tbody tr.selected').removeClass('selected');

    // Select the current row
    selectedRow = datatable.row($(this)).data().DT_RowId;
    $(this).addClass('selected');

    // Enable load btn
    content.closest('.modal')
      .find(".modal-footer [data-action='submit']")
      .removeAttr('disabled');

    e.stopPropagation();
  });

  tableEl.find('tbody').on('click', "a[data-action='filter']", function(e) {
    var link = $(this);
    var query = link.attr('data-param');

    // Re-search data
    datatable.search(query).draw();

    // Don't propagate this further up
    e.stopPropagation();
    return false;
  });
}

function destroyLoadFromRepositoryTable(content) {
  var tableEl = content.find("[data-role='datatable']");

  // Unbind event listeners
  tableEl.find('tbody').off('click', "a[data-action='filter']");
  tableEl.find('tbody').off('click', 'tr');

  // Destroy datatable
  tableEl.DataTable().destroy();
  tableEl.find('tbody').html('');

  selectedRow = null;

  // Disable load btn
  content.closest('.modal')
    .find(".modal-footer [data-action='submit']")
    .attr('disabled', 'disabled');
}

function loadFromRepository() {
  var modal = $('#load-from-repository-modal');

  var checkLinked = $("[data-role='protocol-status-bar']")
    .text();

  var confirmMessage = '';
  if (checkLinked.trim() !== '(unlinked)') {
    confirmMessage = I18n.t('my_modules.protocols.load_from_repository_modal.import_to_linked_task_rep');
  } else {
    confirmMessage = I18n.t('my_modules.protocols.load_from_repository_modal.confirm_message');
  }

  if (selectedRow !== null && confirm(confirmMessage)) {
    modal.find(".modal-footer [data-action='submit']").prop('disabled', true);
    // POST via ajax
    $.ajax({
      url: modal.attr('data-url'),
      type: 'POST',
      dataType: 'json',
      data: { source_id: selectedRow },
      success: function() {
        // Simply reload page
        location.reload();
      },
      error: function(response) {
        if (response.status === 403) {
          HelperModule.flashAlertMsg(I18n.t('general.no_permissions'), 'danger');
        } else {
          alert(response.responseJSON.message);
        }

        modal.modal('hide');
      }
    });
  }
}

function refreshProtocolStatusBar() {
  // Get the status bar URL
  var url = $("[data-role='protocol-status-bar-url']").attr('data-url');

  // Fetch new updated at label
  $.ajax({
    url: url,
    type: 'GET',
    dataType: 'json',
    success: function(data) {
      $('.my-module-protocol-status').replaceWith(data.html);
      initLinkUpdate();
    }
  });
}

function initImport() {
  var fileInput = $("[data-action='load-from-file']");

  // Make sure multiple selections of same file
  // always prompt new modal
  fileInput.find("input[type='file']").on('click', function() {
    this.value = null;
  });

  // Hack to hide "No file chosen" tooltip
  fileInput.attr('title', window.URL ? ' ' : '');

  fileInput.on('change', function(ev) {
    var importUrl = fileInput.attr('data-import-url');
    importProtocolFromFile(
      ev.target.files[0],
      importUrl,
      null,
      true,
      function(datas) {
        var data = datas[0];
        if (data.status === 'ok') {
          // Simply reload page
          location.reload();
        } else if (data.status === 'locked') {
          alert(I18n.t('my_modules.protocols.load_from_file_error_locked'));
        } else {
          if (data.status === 'size_too_large') {
            alert(I18n.t('my_modules.protocols.load_from_file_size_error',
              { size: GLOBAL_CONSTANTS.FILE_MAX_SIZE_MB }));
          } else {
            alert(I18n.t('my_modules.protocols.load_from_file_error'));
          }
          animateSpinner(null, false);
        }
      }
    );
    // Clear input on self
    $(this).val('');
  });
}

function initDetailsDropdown() {
  $('#task-details .task-section-caret').on('click', function() {
    if (!$('.task-details').hasClass('collapsing')) {
      $(this).closest('#task-details').toggleClass('expanded');
    }
  });
}

function initProtocolSectionOpenEvent() {
  $('#protocol-container').on('shown.bs.collapse', function() {
    $(this).find("[data-role='hot-table']").each(function() {
      var $container = $(this).find("[data-role='step-hot-table']");
      var hot = $container.handsontable('getInstance');
      hot.render();
    });
  });
}

/**
 * Initializes page
 */
function init() {
  initEditMyModuleDescription();
  initEditProtocolDescription();
  initLinkUpdate();
  initLoadFromRepository();
  refreshProtocolStatusBar();
  initImport();
  initProtocolSectionOpenEvent();
  initDetailsDropdown();
}

init();
