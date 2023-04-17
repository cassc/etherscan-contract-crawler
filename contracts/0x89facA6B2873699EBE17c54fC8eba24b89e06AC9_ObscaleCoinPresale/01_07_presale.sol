pragma solidity ^0.8.0;
// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ObscaleCoinPresale is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public token;
    IERC20 public usdt;
    uint256 public fixedTokenPrice; // Fixed token price in cents (e.g., 37 for 0.037 USD)
    uint256 public tokensSold;
    bool public isSaleActive;

    event TokensPurchased(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

    constructor(IERC20 _token, IERC20 _usdt, uint256 _fixedTokenPrice) {
        require(address(_token) != address(0), "Token address must be valid");
        token = _token;

        require(address(_usdt) != address(0), "USDT address must be valid");
        usdt = _usdt;

        require(_fixedTokenPrice > 0, "Fixed token price must be greater than 0");
        fixedTokenPrice = _fixedTokenPrice;

        isSaleActive = true;
    }

    function buyTokens(address beneficiary, uint256 usdtAmount) public {
        require(isSaleActive, "Token sale is not active");
        uint256 tokens = _getTokenAmount(usdtAmount);
        tokensSold += tokens;

        usdt.safeTransferFrom(msg.sender, owner(), usdtAmount);
        token.transferFrom(owner(), beneficiary, tokens);
        emit TokensPurchased(msg.sender, beneficiary, usdtAmount, tokens);
    }

    function _getTokenAmount(uint256 usdtAmount) internal view returns (uint256) {
        uint256 realPrice = fixedTokenPrice / 1000;
        uint256 tokens = ((usdtAmount / realPrice) / 10**6) * 10**18;
        return tokens;
    }

    function withdrawTokens() external onlyOwner payable {
        uint256 tokenBalance = token.balanceOf(address(this));
        token.transfer(owner(), tokenBalance);
    }

    function withdrawUSDT() external onlyOwner payable {
        uint256 usdtBalance = usdt.balanceOf(address(this));
        usdt.transfer(owner(), usdtBalance);
    }

    function setFixedTokenPrice(uint256 _fixedTokenPrice) external onlyOwner {
        fixedTokenPrice = _fixedTokenPrice;
        isSaleActive = fixedTokenPrice > 0;
    }

    function toggleSaleStatus() external onlyOwner {
        isSaleActive = !isSaleActive;
    }
}