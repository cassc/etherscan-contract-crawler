// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

import {IPausable} from "../../lib/IPausable.sol";

/**
 * @dev Contract logic responsible for xSwap protocol live control.
 */
interface ILifeControl is IPausable {
    /**
     * @dev Emitted when the termination is triggered by `account`.
     */
    event Terminated(address account);

    /**
     * @dev Pauses xSwap protocol.
     *
     * Requirements:
     * - called by contract owner
     * - must not be in paused state
     */
    function pause() external;

    /**
     * @dev Unpauses xSwap protocol.
     *
     * Requirements:
     * - called by contract owner
     * - must be in paused state
     * - must not be in terminated state
     */
    function unpause() external;

    /**
     * @dev Terminates xSwap protocol.
     *
     * Puts xSwap protocol into the paused state with no further ability to unpause.
     * This action essentially stops protocol so is expected to be called in
     * extraordinary scenarios only.
     *
     * Requires contract to be put into the paused state prior the call.
     *
     * Requirements:
     * - called by contract owner
     * - must be in paused state
     * - must not be in terminated state
     */
    function terminate() external;

    /**
     * @dev Returns whether protocol is terminated ot not.
     *
     * Terminated protocol is guaranteed to be in paused state forever.
     *
     * @return _ `true` if protocol is terminated, `false` otherwise.
     */
    function terminated() external view returns (bool);
}