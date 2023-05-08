// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {APausableFacet} from "@lib-diamond/src/security/pausable/APausableFacet.sol";
import {LibPausable} from "@lib-diamond/src/security/pausable/LibPausable.sol";
import {WithPausable} from "@lib-diamond/src/security/pausable/WithPausable.sol";

import {WithRoles} from "@lib-diamond/src/access/access-control/WithRoles.sol";
import {LibAccessControlEnumerable} from "@lib-diamond/src/access/access-control/LibAccessControlEnumerable.sol";
import {DEFAULT_ADMIN_ROLE} from "@lib-diamond/src/access/access-control/Roles.sol";

import {LibPonzu} from "../libraries/LibPonzu.sol";
import {PonzuStorage} from "../types/ponzu/PonzuStorage.sol";

contract PausableFacet is APausableFacet {
  modifier onlyAuthorized() override {
    LibAccessControlEnumerable.checkRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _;
  }

  /**
   * @dev Returns to normal state.
   *
   * Requirements:
   *
   * - The contract must be paused.
   */
  function unpause() external virtual override whenPaused onlyAuthorized {
    uint256 pTimeSincePaused = LibPausable.timeSincePaused();
    LibPausable.unpause();
    PonzuStorage storage ps = LibPonzu.DS();
    ps.pausedTimeInRound += pTimeSincePaused;
  }
}