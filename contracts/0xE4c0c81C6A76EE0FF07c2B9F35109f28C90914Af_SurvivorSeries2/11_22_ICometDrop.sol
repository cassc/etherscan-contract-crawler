// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { DropEvents } from "../events/DropEvents.sol";

interface ICometDrop is DropEvents {
    /**
     * @notice Set the administrator.
     *
     * @param wallet The address of the administrator.
     */
    function setAdministrator(address wallet) external;
}