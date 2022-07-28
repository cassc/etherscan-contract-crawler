// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract MultiCurrencyTokenV1 is ERC20Upgradeable, OwnableUpgradeable{

    function mint(address to, uint amount) external onlyOwner{
        _mint(to, amount);
    }

    function initialize() external initializer{
        __ERC20_init("Multi Currency Token", "MCT");
    }
}