// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "./ERC20.sol";

contract Abu is ERC20 {
    constructor() ERC20("Abu", "ABU") {
        _mint(msg.sender, 123456789 * 10 ** decimals());
    }
}