// SPDX-License-Identifier: MIT


///web3property.net


pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Web3PropertyNetwork is ERC20, Ownable {
    constructor(address to_mint) ERC20("Web3 Property Network", "W3PN") {
        _mint(to_mint, 1000000000 * 10 ** decimals());
    }
}