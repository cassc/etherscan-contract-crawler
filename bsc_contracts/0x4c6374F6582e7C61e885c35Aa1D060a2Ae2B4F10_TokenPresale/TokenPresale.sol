/**
 *Submitted for verification at BscScan.com on 2023-03-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
}

interface IUSDT {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
}

interface IBUSD {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
}

contract TokenPresale {
    address public owner = 0x7E5f3e212055596A48Bf7C1141661d83dDBD9e91;
    address public tokenAddress = 0xfaAeC3bfAb9AC754108b6099c889ec53112b7584;
    uint256 public salePrice = 30000;
    uint256 public usdtPrice = 125;
    uint256 public busdPrice = 175;
    address public usdtAddress = 0x40D8958FE4C2462C60d08091Bb3d4c9477b2Cc50;
    address public busdAddress = 0x1318489C426E032465eDbDa5A1D32023923aFb87;


    function buyTokens(address _refer) payable public returns (bool) {
        require(msg.value > 0 ether, "Transaction recovery");
        require(tokenAddress != address(0), "Token address not set");

        uint256 _msgValue = msg.value;
        uint256 _tokens = _msgValue * salePrice;

        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(msg.sender, _tokens), "Token transfer failed");

        return true;
    }

    function buyWithUSDT(address _refer, uint256 _usdtAmount) public returns(bool){
        require(_usdtAmount > 0, "USDT amount must be greater than 0");
        require(tokenAddress != address(0), "Token address not set");
        IUSDT usdt = IUSDT(usdtAddress);

        require(usdt.transferFrom(msg.sender, address(this), _usdtAmount), "USDT transfer failed");
        uint256 _token = _usdtAmount * usdtPrice;
        require(IERC20(tokenAddress).transfer(msg.sender, _token), "Token transfer failed");
        return true;
    }

    function buyTokensWithBUSD(address _refer, uint256 _busdAmount) public returns (bool) {
        require(_busdAmount > 0, "Transaction recovery");
        require(tokenAddress != address(0), "Token address not set");

        IBUSD busd = IBUSD(busdAddress);
        IERC20 token = IERC20(tokenAddress);

        uint256 _busdtokens = _busdAmount * busdPrice;
        require(token.transfer(msg.sender, _busdtokens), "Token transfer failed");

        require(busd.transferFrom(msg.sender, address(this), _busdAmount), "USDT transfer failed");

        return true;
    }



    function withdraw(address payable _to) public {
        require(msg.sender == owner, "Only owner can withdraw");
        _to.transfer(address(this).balance);
    }
}