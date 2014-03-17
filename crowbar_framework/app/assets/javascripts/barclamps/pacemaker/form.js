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

$(document).ready(function($) { $('#stonith_per_node_container').stonithNodePlugins(); });
