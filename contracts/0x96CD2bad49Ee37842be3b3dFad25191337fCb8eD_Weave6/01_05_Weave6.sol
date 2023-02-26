// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Weave6 is ERC20 {
    constructor() ERC20("Weave6", "W6") {
       _mint(msg.sender, 1e27);
    }
}