// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GoSpace is ERC20, Ownable {
    constructor(string memory name, string memory symbol, address multisig, uint amount) ERC20(name, symbol) {
        _mint(multisig, amount * 10 ** decimals());
    }
}