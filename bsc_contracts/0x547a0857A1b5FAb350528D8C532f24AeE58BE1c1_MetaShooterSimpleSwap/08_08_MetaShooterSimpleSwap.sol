// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract MetaShooterSimpleSwap is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    uint32 constant HUNDRED_PERCENT_BP = 10000;

    IERC20 public token1;
    IERC20 public token2;
    uint256 public exchangeFee;
    uint256 public exchangeRate;

    event ESwap(
        address recipient,
        address from,
        address to,
        uint256 amount,
        uint256 exchangeRate,
        uint256 exchangeFee
    );

    constructor(
        IERC20 _token1,
        IERC20 _token2,
        uint256 _exchangeRate,
        uint256 _exchangeFee
    ) {
        require(address(_token1) != address(0));
        require(address(_token2) != address(0));
        token1 = _token1;
        token2 = _token2;
        exchangeRate = _exchangeRate;
        exchangeFee = _exchangeFee;
    }

    function swap(address from, uint256 fromAmount) external nonReentrant {
        require(IERC20(from).balanceOf(msg.sender) >= fromAmount, "MetaShooterSimpleSwap: sender doesnt have enough balance swap");

        IERC20 fromToken;
        IERC20 toToken;
        uint256 toAmount;
        uint256 fee;
        uint256 toAmountWithFee;

        if (address(token1) == from){
            fromToken = token1;
            toToken = token2;
            toAmount = fromAmount * exchangeRate / HUNDRED_PERCENT_BP;
        } else {
            fromToken = token2;
            toToken = token1;
            toAmount = fromAmount * HUNDRED_PERCENT_BP / exchangeRate;
        }

        fee = toAmount * exchangeFee / HUNDRED_PERCENT_BP;
        toAmountWithFee = toAmount - fee;

        require(toAmountWithFee > 0, "MetaShooterSimpleSwap: swap amount to small to return");
        require(IERC20(address(toToken)).balanceOf(address(this)) >= toAmountWithFee,
            "MetaShooterSimpleSwap: contract doesnt have enough balance to return");

        fromToken.safeTransferFrom(msg.sender, address(this), fromAmount);
        toToken.transfer(msg.sender, toAmountWithFee);

        emit ESwap(msg.sender, address(fromToken), address(toToken), fromAmount, exchangeRate, exchangeFee);
    }

    function withdrawToken(address tokenAddress, uint256 amount) external onlyOwner {
        IERC20(tokenAddress).safeTransfer(msg.sender, amount);
    }

    function setExchangeRate(uint256 _exchangeRate) public onlyOwner {
        exchangeRate = _exchangeRate;
    }

    function setExchangeFee(uint256 _exchangeFee) public onlyOwner {
        exchangeFee = _exchangeFee;
    }
}