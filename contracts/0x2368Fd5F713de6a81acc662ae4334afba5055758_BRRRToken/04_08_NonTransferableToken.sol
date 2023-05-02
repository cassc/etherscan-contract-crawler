// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract NonTransferableToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function transfer(address, uint256) public pure override returns (bool) {
        revert("NonTransferableToken: transfer not allowed");
    }

    function transferFrom(address, address, uint256) public pure override returns (bool) {
        revert("NonTransferableToken: transferFrom not allowed");
    }

    function approve(address, uint256) public pure override returns (bool) {
        revert("NonTransferableToken: approve not allowed");
    }
}