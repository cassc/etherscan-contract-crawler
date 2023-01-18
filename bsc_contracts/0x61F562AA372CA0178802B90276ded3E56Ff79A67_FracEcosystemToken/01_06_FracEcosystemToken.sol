// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FracEcosystemToken is ERC20, Ownable {
    constructor() ERC20("Frac Ecosystem Token", "FRAC") {
        _mint(msg.sender, 500000000 * 10 ** decimals());
    }
}