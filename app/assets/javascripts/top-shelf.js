//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See doc/COPYRIGHT.rdoc for more details.
//++

(function($) {

  function mergeOptions(options) {
    if (typeof options === "string") {
      options = { message: options };
    }
    return $.extend({}, $.fn.topShelf.defaults, options);
  };

  $.fn.topShelf = function(options) {
    var opts = mergeOptions(options);
    var message = this;
    var topShelf = $("<div/>").addClass(opts.className)

    if (message.length === 0) {
      topShelf.append($("<h1/>").append(opts.title))
              .append($("<p/>").append(opts.message))
              .append($("<h2/>").append(
                $("<a/>").append(opts.link)
                         .attr({"href": opts.url})
              ));
    } else {
      topShelf.append(message);
    }

    $("body").prepend(topShelf)

    return this;
  };

  $.fn.topShelf.defaults = {
    className: "top-shelf",
    title: "",
    message: "",
    link: "",
    url: ""
  };

}(jQuery));
