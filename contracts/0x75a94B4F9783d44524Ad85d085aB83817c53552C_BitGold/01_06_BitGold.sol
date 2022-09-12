// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/*
 *  @title Wildland's Token
 *  Copyright @ Wildlands
 *  App: https://wildlands.me
 */

contract BitGold is ERC20("Bitgold", "BTG"), Ownable {

    constructor(address treasury) {
        _mint(treasury, 11e6 * 10 ** decimals());
    }
}