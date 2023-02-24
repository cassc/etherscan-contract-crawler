// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ShowMeta is ERC20 {
    constructor() ERC20("ShowMeta", "SHOW") {
        _mint(msg.sender, 42e24);
    }
}