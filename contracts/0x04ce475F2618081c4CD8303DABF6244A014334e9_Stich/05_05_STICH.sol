// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC20.sol";

contract Stich is ERC20 {
    constructor() ERC20("STICH", "STICH") {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
    }
}