// SPDX-License-Identifier: MIT
// Created by BondSwap https://bondswap.org

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract BondSwapPresale is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public startTime;
    uint256 public closeTime;
    uint256 public pricePerToken;
    address public bonds;

    constructor(
        uint256 _start,
        uint256 _end,
        uint256 _price,
        address _bonds
    ) {
        startTime = _start;
        closeTime = _end;
        pricePerToken = _price;
        bonds = _bonds;
    }

    function buy(uint256 amount) external payable nonReentrant whenNotPaused {
        require(block.timestamp >= startTime, "Presale:NOT_YET_STARTED");
        require(block.timestamp <= closeTime, "Presale:SALE_ENDED");
        require(amount > 0, "Presale:INVALID_AMOUNT");
        require(
            msg.value >= amount * pricePerToken,
            "Presale:NOT_ENOUGH_ETHER"
        );
        require(
            IERC20(bonds).balanceOf(address(this)) >= 10**18 * amount,
            "Presale:NOT_ENOUGH_BONDS_TOKENS_LEFT"
        );

        IERC20(bonds).safeTransfer(msg.sender, amount * 10**18);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        external
        onlyOwner
    {
        require(tokenAddress != bonds, "Presale:CANT_MOVE_BONDS");
        IERC20(tokenAddress).safeTransfer(msg.sender, tokenAmount);
    }

    function withdraw() public onlyOwner {
        require(block.timestamp >= closeTime, "Presale:NOT_ENDED");

        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);

        if (IERC20(bonds).balanceOf(address(this)) > 0) {
            IERC20(bonds).safeTransfer(
                msg.sender,
                IERC20(bonds).balanceOf(address(this))
            );
        }
    }
}