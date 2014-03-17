;(function($, doc, win) {
  'use strict';

  function StonithNodePlugins(el, options) {
    this.root = $(el);
    this.html = {
       table_row: '<tr data-id="{0}"><td>{0}</td><td><input type="text" class="form-control input-sm" value="{1}"/></td></tr>'
    };

    this.options = $.extend(
      {
        storage: '#proposal_attributes',
        path: 'stonith/per_node/nodes',
        watchedRoles: ['pacemaker-cluster-founder', 'pacemaker-cluster-member']
      }
    );

    this.initialize();
  }

  StonithNodePlugins.prototype._ignore_event = function(evt, data) {
    var self = this;

    var row_id = '[data-id="{0}"]'.format(data.id);
    var row    = $(evt.target).find(row_id)

    if (self.options.watchedRoles.indexOf(data.role) == -1) { return true; }
    if (evt.type == 'nodeListNodeAllocated' && row.length > 0) { return true; }
    if (evt.type == 'nodeListNodeUnallocated' && row.length == 0) { return true; }

    return false;
  };

  StonithNodePlugins.prototype.initialize = function() {
    var self = this;

    // Render what we already have
    self.renderPluginParams();
    // And start listening on changes
    self.registerEvents();
  };

  StonithNodePlugins.prototype.registerEvents = function() {
    var self = this;

    // Update JSON on input changes
    this.root.find('tbody tr').live('change', function(evt) {
      var elm = $(this);
      var id  = elm.data('id');
      var val = elm.find('input').val();

      self.writeJson(id, val, "string");
    });

    // Append new table row and update JSON on node alloc
    this.root.on('nodeListNodeAllocated', function(evt, data) {
      if (self._ignore_event(evt, data)) { return; }

      $(this).find('tbody').append(self.html.table_row.format(data.id, ''));
      self.writeJson(data.id, "", "string");
    });

    // Remove the table row and update JSON on node dealloc
    this.root.on('nodeListNodeUnallocated', function(evt, data) {
      if (self._ignore_event(evt, data)) { return; }

      $(this).find('[data-id="{0}"]'.format(data.id)).remove();
      self.removeJson(data.id, "", "string");
    });
  };

  // Initial render
  StonithNodePlugins.prototype.renderPluginParams = function() {
    var self = this;
    var params = $.map(self.retrievePluginParams(), function(node_id, params) {
      return self.html.table_row.format(node_id, params);
    });
    this.root.find('tbody').html(params.join(''));
  };

  // FIXME: these could be refactored into a common plugin
  StonithNodePlugins.prototype.retrievePluginParams = function() {
    return $(this.options.storage).readJsonAttribute(
      this.options.path,
      {}
    );
  };

  StonithNodePlugins.prototype.writeJson = function(key, value, type) {
    return $(this.options.storage).writeJsonAttribute(
      '{0}/{1}'.format(
        this.options.path,
        key
      ),
      value,
      type
    );
  };

  StonithNodePlugins.prototype.removeJson = function(key, value, type) {
    return $(this.options.storage).removeJsonAttribute(
      '{0}/{1}'.format(
        this.options.path,
        key
      ),
      value,
      type
    );
  };

  $.fn.stonithNodePlugins = function(options) {
    return this.each(function() {
      new StonithNodePlugins(this, options);
    });
  };
}(jQuery, document, window));

function update_no_quorum_policy(evt, init) {
  var no_quorum_policy_el = $('#crm_no_quorum_policy');
  var non_forced_policy = no_quorum_policy_el.data('non-forced');
  var was_forced_policy = no_quorum_policy_el.data('is-forced');
  var non_founder_members = $('#pacemaker-cluster-member').children().length;

  if (non_forced_policy == undefined) {
    non_forced_policy = "stop";
  }

  if (evt != undefined) {
    // 'nodeListNodeAllocated' is fired after the element has been added, so
    // nothing to do. However, 'nodeListNodeUnallocated' is fired before the
    // element is removed, so we need to fix the count.
    if (evt.type == 'nodeListNodeUnallocated') { non_founder_members -= 1; }
  }

  if (non_founder_members > 1) {
    if (was_forced_policy) {
      no_quorum_policy_el.val(non_forced_policy);
      no_quorum_policy_el.removeData('non-forced');
    }
    no_quorum_policy_el.data('is-forced', false)
    no_quorum_policy_el.removeAttr('disabled');
  } else {
    if (!init && !was_forced_policy) {
      no_quorum_policy_el.data('non-forced', no_quorum_policy_el.val());
    }
    no_quorum_policy_el.data('is-forced', true)
    no_quorum_policy_el.val("ignore");
    no_quorum_policy_el.attr('disabled', 'disabled');
  }
}

$(document).ready(function($) {
  $('#stonith_per_node_container').stonithNodePlugins();

  $('#crm_no_quorum_policy').on('nodeListNodeAllocated', function(evt, data) {
    update_no_quorum_policy(evt, false)
  });
  $('#crm_no_quorum_policy').on('nodeListNodeUnallocated', function(evt, data) {
    update_no_quorum_policy(evt, false)
  });

  update_no_quorum_policy(undefined, true)
});
