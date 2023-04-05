import Utility from './utility';
import { createTooltip } from './utility';

let UserTooltip = {};

UserTooltip.SELECTOR = "*:not(.user-tooltip-name) > a.user, a.dtext-user-id-link, a.dtext-user-mention-link";
UserTooltip.SHOW_DELAY = 500;
UserTooltip.HIDE_DELAY = 125;
UserTooltip.DURATION = 250;
UserTooltip.MAX_WIDTH = 600;

UserTooltip.initialize = function () {
  createTooltip("user-tooltip", {
    delay: [UserTooltip.SHOW_DELAY, UserTooltip.HIDE_DELAY],
    duration: UserTooltip.DURATION,
    maxWidth: UserTooltip.MAX_WIDTH,
    target: UserTooltip.SELECTOR,
    appendTo: "parent",
    touch: false,

    onShow: UserTooltip.on_show,
    onHide: UserTooltip.on_hide,
  });
};

UserTooltip.on_show = async function (instance) {
  let $target = $(instance.reference);
  let $tooltip = $(instance.popper);

  // skip if tooltip has already been rendered.
  if ($tooltip.has(".user-tooltip-body").length) {
    return;
  }

  try {
    $tooltip.addClass("tooltip-loading");

    if ($target.is("a.dtext-user-id-link")) {
      let user_id = /\/users\/(\d+)/.exec($target.attr("href"))[1];
      instance._request = $.get(`/users/${user_id}`, { variant: "tooltip" });
    } else if ($target.is("a.user")) {
      let user_id = $target.attr("data-user-id");
      instance._request = $.get(`/users/${user_id}`, { variant: "tooltip" });
    } else if ($target.is("a.dtext-user-mention-link")) {
      let user_name = $target.attr("data-user-name");
      instance._request = $.get(`/users`, { name: user_name, variant: "tooltip" });
    }

    let html = await instance._request;
    instance.setContent(html);

    $tooltip.removeClass("tooltip-loading");
  } catch (error) {
    if (error.status !== 0 && error.statusText !== "abort") {
      Utility.error(`Error displaying tooltip (error: ${error.status} ${error.statusText})`);
    }
  }
};

UserTooltip.on_hide = function (instance) {
  if (instance._request?.state() === "pending") {
    instance._request.abort();
  }
}

$(document).ready(UserTooltip.initialize);

export default UserTooltip
