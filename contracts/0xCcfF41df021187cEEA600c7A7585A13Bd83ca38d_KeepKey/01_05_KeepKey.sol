// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract KeepKey is ERC20 {
    constructor(uint256 _supply) ERC20("KeepKey Test", "KKt") {
        _mint(msg.sender, _supply);
    }
}