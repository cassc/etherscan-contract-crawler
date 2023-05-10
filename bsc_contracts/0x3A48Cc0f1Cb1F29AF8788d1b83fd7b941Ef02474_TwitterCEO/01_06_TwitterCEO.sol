//SPDX-License-Identifier: Unlicense
pragma solidity = 0.8.9;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/// @title Bitindi Chain
contract TwitterCEO is ERC20Burnable {

    constructor () ERC20("Twitter CEO", "TCEO") {
        _mint(msg.sender, 100_000_000 * (10 ** decimals()));
    }
}