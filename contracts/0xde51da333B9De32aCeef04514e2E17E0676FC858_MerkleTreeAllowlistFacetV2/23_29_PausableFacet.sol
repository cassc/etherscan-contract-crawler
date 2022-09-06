// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import {AccessControlModifiers} from "../AccessControl/AccessControlModifiers.sol";
import {PausableLib} from "./PausableLib.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableFacet is AccessControlModifiers {
    function pause() public onlyOwner {
        PausableLib._pause();
    }

    function unpause() public onlyOwner {
        PausableLib._unpause();
    }

    function paused() public view returns (bool) {
        return PausableLib._paused();
    }
}