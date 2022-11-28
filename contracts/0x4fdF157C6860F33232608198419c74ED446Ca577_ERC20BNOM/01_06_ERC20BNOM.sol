// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20BNOM is ERC20, ERC20Burnable {

    // 100 million initial supply
    // This will be sent to the Bonding Contract
    uint256 public constant INITIAL_SUPPLY = 100000000;

    constructor () ERC20("Onomy", "bNOM") {
        _mint(msg.sender, INITIAL_SUPPLY * (10 ** 18));
    }
}