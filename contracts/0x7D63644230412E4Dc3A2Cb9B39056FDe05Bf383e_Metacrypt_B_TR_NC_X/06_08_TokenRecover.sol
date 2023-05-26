// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@uniswap/v2-periphery/contracts/interfaces/IERC20.sol";

import "./ERC20Ownable.sol";

contract TokenRecover is ERC20Ownable {
    function recoverToken(address tokenAddress, uint256 tokenAmount) public virtual onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }
}