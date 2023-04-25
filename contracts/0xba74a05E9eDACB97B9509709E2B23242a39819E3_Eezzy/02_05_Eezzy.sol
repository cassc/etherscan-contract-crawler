// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


import "./ERC20.sol";

contract Eezzy is ERC20 {
    constructor() ERC20("EEZZY", "EEZZY") {
        _mint(msg.sender, 6666000000 * 10 ** decimals());
    }
}