// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PepeV3 is ERC20 {
    constructor() ERC20("PEPE V3", "P3P3") {
        _mint(msg.sender, 69000000000 * 10 ** decimals());
    }
}