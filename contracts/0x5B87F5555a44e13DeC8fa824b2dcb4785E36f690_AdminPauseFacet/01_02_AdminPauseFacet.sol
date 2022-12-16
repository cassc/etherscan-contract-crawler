// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**************************************************************\
 * AdminPauseFacet authored by Sibling Labs
 * Version 0.2.0
/**************************************************************/

import { GlobalState } from "../libraries/GlobalState.sol";

contract AdminPauseFacet {
    event Paused(address account);
    event Unpaused(address account);

    /**
    * @dev Returns bool indicating whether or not the contract
    *      is paused.
    */
    function paused() external view returns (bool) {
        return GlobalState.getState().paused;
    }

    /**
    * @dev Toggles paused status of contract. Only callable by
    *      admins.
    */
    function togglePause() external {
        GlobalState.requireCallerIsAdmin();
        
        bool prior = GlobalState.getState().paused;
        GlobalState.getState().paused = !prior;
        if (prior) {
            emit Unpaused(msg.sender);
        } else {
            emit Paused(msg.sender);
        }
    }
}