// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Sendable {
    constructor() {}

    function sendEth(address payable to, uint256 amount) internal {
        (bool sent, ) = to.call{value: amount}("");
        require(sent, "Sendable: failed to send Ether");
    }
}