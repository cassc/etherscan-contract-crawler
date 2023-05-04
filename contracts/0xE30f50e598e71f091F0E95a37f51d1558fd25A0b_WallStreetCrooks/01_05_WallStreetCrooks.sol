// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract WallStreetCrooks is ERC20 {
    constructor() ERC20("WallStreetCrooks", "WSC") {
        _mint(msg.sender, 69000000000 * 10 ** decimals());
    }
}