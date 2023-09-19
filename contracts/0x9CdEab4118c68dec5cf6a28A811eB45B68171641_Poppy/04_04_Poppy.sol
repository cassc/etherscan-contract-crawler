// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC20.sol";

contract Poppy is ERC20 {
    constructor() ERC20("Poppy", "POPPY") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}