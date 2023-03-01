// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IJumpStartTicket {
    function mintTicket(address ticketMinter, uint256 quantity) external;
}