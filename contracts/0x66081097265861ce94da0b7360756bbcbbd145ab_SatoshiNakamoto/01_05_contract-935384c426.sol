// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

contract SatoshiNakamoto is ERC20 {
    constructor() ERC20("SatoshiNakamoto", "Satoshi") {
        _mint(msg.sender, 24000000 * 10 ** decimals());
    }
}