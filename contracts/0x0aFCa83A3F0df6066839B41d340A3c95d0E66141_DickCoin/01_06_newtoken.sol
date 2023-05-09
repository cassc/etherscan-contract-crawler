// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DickCoin is ERC20, Ownable {
    constructor() ERC20("Dick Coin", "DICK") {
        uint256 initialSupply = 100000000000000 * (10 ** decimals());
        _mint(msg.sender, initialSupply);
    }
}