// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenSale is Ownable {
    IERC20 public token = IERC20(0x33D845D6E70ed8F6334C273358d1c5a320449C6F);
    uint8 public tokenDecimals = 3;
    IERC20 public USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    uint8 public USDTDecimals = 6;
    uint256 public conversionRate = 100; //in bips

    event LiquidityAdded(uint256 tokenAmount);
    event LiquidityRemoved(uint256 tokenAmount);
    event conversionRateUpdated(uint256 conversionRate);
    event tokenSold(address to, uint256 tokenAmount);
    event USDTWithdrawn(address to, uint256 USDTAmount);

    function fundContract(uint256 _tokenAmount) external onlyOwner {
        require(token.allowance(msg.sender, address(this)) >= _tokenAmount, "Insufficient token allowance");
        token.transferFrom(msg.sender, address(this), _tokenAmount);
        emit LiquidityAdded(_tokenAmount);
    }

    function buy(uint256 _USDTAmount) external {
        require(USDT.allowance(msg.sender, address(this)) >= _USDTAmount, "Insufficient USDT allowance");
        require(USDT.balanceOf(msg.sender) >= _USDTAmount, "Insuffient USDT balance in user address");
        uint256 _tokenAmount = (_USDTAmount * conversionRate/100) * 10 ** (tokenDecimals - USDTDecimals); 
        require(token.balanceOf(address(this)) >= _tokenAmount, "Insuffient liquidity for this trade");
        USDT.transferFrom(msg.sender, address(this), _USDTAmount);
        token.transfer(msg.sender, _tokenAmount);

        emit tokenSold(msg.sender, _tokenAmount);
    }

    function updateConversionRate(uint256 _conversionRate) external onlyOwner {
        conversionRate = _conversionRate;
        emit conversionRateUpdated(_conversionRate);
    }

    function withdrawUSDT(uint256 _amount, address _withdrawalAddress) external onlyOwner {
        require(USDT.balanceOf(address(this)) >= _amount, "Insufficient USDT balance in contract");
        USDT.transfer(_withdrawalAddress, _amount);

        emit USDTWithdrawn(_withdrawalAddress, _amount);

    }

    function withdrawToken(uint256 _amount, address _withdrawalAddress) external onlyOwner {
        require(token.balanceOf(address(this)) >= _amount, "Insufficient token balance in contract");
        token.transfer(_withdrawalAddress, _amount);

        emit LiquidityRemoved(_amount);
    }

    function getTokenLiquidity() view public returns(uint256) {
        return token.balanceOf(address(this));
    }

    ///// Admin Methods /////////////////

    function updateTokenDetails(address _tokenAddress, uint8 _tokenDecimals) external onlyOwner {
        token = IERC20(_tokenAddress);
        tokenDecimals = _tokenDecimals;
    }

    function updateUSDTDetails(address _USDTAddress, uint8 _USDTDecimals) external onlyOwner {
        USDT = IERC20(_USDTAddress);
        USDTDecimals = _USDTDecimals;
    }

}