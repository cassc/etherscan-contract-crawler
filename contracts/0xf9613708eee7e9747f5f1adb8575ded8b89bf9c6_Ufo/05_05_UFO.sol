// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "./ERC20.sol";

contract Ufo is ERC20 {
    constructor() ERC20("Ufo", "UFO") {
        _mint(msg.sender, 123456789 * 10 ** decimals());
    }
}