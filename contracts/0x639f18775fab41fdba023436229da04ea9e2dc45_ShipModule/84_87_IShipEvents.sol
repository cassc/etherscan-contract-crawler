// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// Actions that the ship can take
interface IShipEvents {
    event Abandon(address captain, address safe, uint256 refund);
}