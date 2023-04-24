// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
//import "hardhat/console.sol";

interface brigeGenesis {
    function getAmountsOutExternalToWeth(uint256 amountIn) external view returns (uint256 amounts);
}


 contract GnsPrice is Ownable, ReentrancyGuard  {
    using SafeMath for uint256;


    uint256 contractReleaseDate; 
    address  EXTERNAL_AIG;
    address  SwapContract;
    brigeGenesis brige;

    IERC20 USDT;

    uint256 minBuyAmount = 100000000000000000000; // 100 usdt

    constructor(
        address _USDT, 
        address _EXTERNAL_AIG,
        address _SwapContract,
        address _brige
        ) {
        USDT = IERC20(_USDT);
        EXTERNAL_AIG = _EXTERNAL_AIG;
        SwapContract = _SwapContract;
        brige = brigeGenesis(_brige);
        contractReleaseDate = block.timestamp;
    }

    event BuyPack(address indexed user, uint256 amount, uint256 token);

    function buyPackUSDT(uint256 _usdtAmount) public {
        require(_usdtAmount >= minBuyAmount, "not enough amount");

        require(USDT.balanceOf(msg.sender) >= _usdtAmount, "insufficient balance");
        USDT.transferFrom(msg.sender, SwapContract, _usdtAmount);

        emit BuyPack(msg.sender, _usdtAmount, 1);
    }

    function buyPackAIG(uint256 _aigAmount) public {
        uint256 USD = brige.getAmountsOutExternalToWeth(_aigAmount);

        require(USD >= minBuyAmount, "not enough amount");

        require(IERC20(EXTERNAL_AIG).balanceOf(msg.sender) >= _aigAmount, "insufficient balance");

        IERC20(EXTERNAL_AIG).transferFrom(msg.sender, SwapContract, _aigAmount);

        emit BuyPack(msg.sender, USD, 2);
    }

    //admin functions ------------------------------------------------------------------------

    function outTokens(address _token, address _to, uint256 _amount) public onlyOwner {
        IERC20(_token).transfer(_to, _amount);
    }

    function changeMinBuyAmount(uint256 _amount) public onlyOwner{
        minBuyAmount = _amount;
    }

    function changeContractReleaseDate(uint256 _contractReleaseDate) public onlyOwner {
        contractReleaseDate = _contractReleaseDate;
    }

}