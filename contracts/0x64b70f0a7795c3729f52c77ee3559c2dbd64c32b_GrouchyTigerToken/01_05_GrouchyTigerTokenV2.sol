// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

contract GrouchyTigerToken is ERC20 {
    constructor() ERC20("GrouchyTigerToken", "GTT") {
        _mint(msg.sender, 10000000000 * 10 ** decimals());
    }
}