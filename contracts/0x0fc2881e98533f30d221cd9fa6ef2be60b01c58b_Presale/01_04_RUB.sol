// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface USDT_IERC20 {
    function transferFrom(address from, address to, uint256 amount) external;

    function transfer(address to, uint256 value) external;
}

contract Presale is Ownable {
    address public tokenAddress = 0x5AE85201082A0a5059B553478e240a63FA0aAc50;
    address public USDTAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    uint256 public tokenPerUSDT = 910 * 10 ** 11; // 91 Token = 1 USDT
    uint256 public minBuyUSDT = 1 * 10 ** 6; // Min buy 1 USDT

    uint256 public amountRaisedUSDT;
    bool public presaleStatus = true;

    function buyTokens(uint256 weiAmountUSDT) public {
        require(presaleStatus, "Presale is finished");
        require(weiAmountUSDT >= minBuyUSDT, "Minimal amount is not reached");

        USDT_IERC20 USDT = USDT_IERC20(USDTAddress);
        USDT.transferFrom(msg.sender, address(this), weiAmountUSDT);

        uint256 tokenAmount = weiAmountUSDT * tokenPerUSDT;
        amountRaisedUSDT = amountRaisedUSDT + (weiAmountUSDT);

        IERC20 token = IERC20(tokenAddress);
        token.transfer(msg.sender, tokenAmount);
    }

    function startstopPresale(bool state) external onlyOwner {
        presaleStatus = state;
    }

    function changePrice(uint256 _price) external onlyOwner {
        tokenPerUSDT = _price;
    }

    function changeToken(address _token) external onlyOwner {
        tokenAddress = _token;
    }

    function changeUSDT(address _USDTtoken) external onlyOwner {
        USDTAddress = _USDTtoken;
    }

    function changeMinimumLimits(uint256 _minBuyUSDT) external onlyOwner {
        minBuyUSDT = _minBuyUSDT;
    }

    function transferTokens(uint256 _value) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(msg.sender, _value);
    }

    function transferUSDT(uint256 _value) external onlyOwner {
        USDT_IERC20 USDT = USDT_IERC20(USDTAddress);
        USDT.transfer(msg.sender, _value);
    }
}