// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LiquidityReserve is Ownable {
    IERC20 public token;

    constructor(IERC20 token_) {
        require(address(token_) != address(0), "Token address can't be address zero");
        token = token_;
    }

    function approveForAddingLiquidity(address contractAddress) external onlyOwner {
        IERC20(token).approve(contractAddress, type(uint256).max);
    }
}