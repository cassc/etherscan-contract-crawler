// SPDX-License-Identifier: MIT

// Developed by:
//////////////////////////////////////////////solarprotocol.io//////////////////////////////////////////
//_____/\\\\\\\\\\\_________/\\\\\_______/\\\__0xFluffyBeard__/\\\\\\\\\_______/\\\\\\\\\_____        //
// ___/\\\/////////\\\_____/\\\///\\\____\/\\\_______________/\\\\\\\\\\\\\___/\\\///////\\\___       //
//  __\//\\\______\///____/\\\/__\///\\\__\/\\\______________/\\\/////////\\\_\/\\\_____\/\\\___      //
//   ___\////\\\__________/\\\______\//\\\_\/\\\_____________\/\\\_______\/\\\_\/\\\\\\\\\\\/____     //
//    ______\////\\\______\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_\/\\\//////\\\____    //
//     _________\////\\\___\//\\\______/\\\__\/\\\_____________\/\\\/////////\\\_\/\\\____\//\\\___   //
//      __/\\\______\//\\\___\///\\\__/\\\____\/\\\_____________\/\\\_______\/\\\_\/\\\_____\//\\\__  //
//       _\///\\\\\\\\\\\/______\///\\\\\/_____\/\\\\\\\\\\\\\\\_\/\\\_______\/\\\_\/\\\______\//\\\_ //
//        ___\///////////__________\/////_______\///////////////__\///________\///__\///________\///__//
////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.9;

import {IPausable} from "./IPausable.sol";
import {LibPausable} from "./LibPausable.sol";
import {LibUtils} from "../libraries/LibUtils.sol";

abstract contract PausableController is IPausable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev Emitted when the exempt from pause status of `account` is updated.
     */
    event UpdateExemptFromPause(address account, bool flag);

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() external view returns (bool) {
        return LibPausable.paused();
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() external {
        LibUtils.enforceIsContractOwner();
        LibPausable.enforceNotPaused();

        LibPausable.pause();
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() external {
        LibUtils.enforceIsContractOwner();
        LibPausable.enforcePaused();

        LibPausable.unpause();
    }

    /**
     * @dev Returns true if `account` is exempt from the pause.
     */
    function isExemptFromPause(address account) external view returns (bool) {
        LibUtils.enforceIsContractOwner();

        return LibPausable.isExemptFromPause(account);
    }

    /**
     * Updates the exempt from pause state of `account` to `flag`.
     */
    function setExemptFromPause(address account, bool flag) external {
        LibUtils.enforceIsContractOwner();

        LibPausable.setExemptFromPause(account, flag);
    }
}