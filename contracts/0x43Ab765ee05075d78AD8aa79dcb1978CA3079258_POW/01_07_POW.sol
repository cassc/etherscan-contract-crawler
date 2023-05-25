// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

contract POW is ERC20Burnable {

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address receiver
    ) ERC20(name, symbol) {
        _mint(receiver, initialSupply);
    }
}