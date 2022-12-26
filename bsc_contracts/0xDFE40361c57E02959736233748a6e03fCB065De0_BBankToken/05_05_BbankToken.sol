// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BBankToken is ERC20 {
    constructor () ERC20("BBANK", "BBA") {
        _mint(msg.sender, 80000000 * 10 ** uint(decimals()));
    }
}