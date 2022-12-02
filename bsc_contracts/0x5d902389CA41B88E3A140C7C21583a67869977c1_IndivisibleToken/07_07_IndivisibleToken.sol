// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../includes/token/BEP20/IndivisibleBEP20.sol";

contract IndivisibleToken is IndivisibleBEP20 {
    constructor(string memory _name, string memory _symbol) IndivisibleBEP20(_name, _symbol) {}
}