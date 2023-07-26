// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract ZuckPepe is Ownable, ERC20 {
    
    constructor(uint256 _totalSupply) ERC20("ZuckPepe", "ZuckPepe") {
        _mint(msg.sender, _totalSupply);
    }

    
}