// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


import "./ERC20.sol";

contract FKG is ERC20 {
    constructor() ERC20("FUKINGO", "FKG") {
        _mint(msg.sender, 6969000000 * 10 ** decimals());
    }
}