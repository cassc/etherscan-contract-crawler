//SPDX-License-Identifier: Unlicense
//Company: BOSCoin, 2022/11/02
//Writer: Full Moon
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract BOScoin is ERC20Burnable, Ownable {
    
    using SafeERC20 for IERC20;

    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        _mint(_msgSender(), initialSupply);
    }
}