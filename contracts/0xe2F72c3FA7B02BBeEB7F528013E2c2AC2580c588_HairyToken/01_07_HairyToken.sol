// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HairyToken is ERC20, ERC20Burnable, Ownable {
    constructor(uint256 _totalSupply) ERC20("HAIRY", "HAIRY") {
        _mint(msg.sender, _totalSupply);
    }
}