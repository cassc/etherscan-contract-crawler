// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ThreeBToken is ERC20 {
    constructor () ERC20("ThreeB Token", "THREEB") {
        _mint(msg.sender, 21000000 * 10 ** uint(decimals()));
    }
}