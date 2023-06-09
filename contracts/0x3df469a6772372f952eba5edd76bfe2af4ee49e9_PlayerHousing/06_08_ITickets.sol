// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/// @title Solarbots Tickets Interface
/// @author Solarbots (https://solarbots.io)
interface ITickets {
    function burn(address from, uint256 id, uint256 amount) external;
}