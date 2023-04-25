// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


import "./ERC20.sol";

contract Chadlon is ERC20 {
    constructor() ERC20("Chadlon", "CHADN") {
        _mint(msg.sender, 10000000000 * 10 ** decimals());
    }
}