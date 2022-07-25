//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract MalibuCoinI is IERC20, Ownable {
         uint256 public maxSupply;

        function getUnclaimedMalibuCoins(address account) external view virtual returns (uint256 amount);
        
        function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool);

        function balanceOf(address account) public view virtual override returns (uint256);
}