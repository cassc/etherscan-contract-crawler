// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "./ERC20.sol";

contract Fbi is ERC20 {
    constructor() ERC20("Fbi", "FBI") {
        _mint(msg.sender, 123456789 * 10 ** decimals());
    }
}