// SPDX-License-Identifier: UNLICENSED

/*
🔥 TG: https://t.me/fuckbearmarkt

🐦 Twitter: https://twitter.com/FuckBearMarkt

Ⓜ️ Medium: https://medium.com/@fbmtoken

🌐 Website: https://fuckbearmarket.wtf/

*/

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IFuckBearMarket.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract FeesManager is Initializable, OwnableUpgradeable {
    using SafeMath for uint256;

    uint256 public buyBurnFee;
    uint256 public buyDevAndMarketingFee;
    uint256 public buyTotalFees;

    uint256 public sellBurnFee;
    uint256 public sellDevAndMarketingFee;
    uint256 public sellTotalFees;

    IFuckBearMarket public fbmContract;
    address public fbmAddress;

    function initialize() external initializer {
        __Ownable_init();
        buyBurnFee = 6;
        buyDevAndMarketingFee = 2;
        buyTotalFees = buyBurnFee + buyDevAndMarketingFee;

        sellBurnFee = 6;
        sellDevAndMarketingFee = 2;
        sellTotalFees = sellBurnFee + sellDevAndMarketingFee;
    }

    // Main burn and fees algorithm, might change for optimisation
    function estimateFees(
        bool _isSelling,
        bool _isBuying,
        uint256 _amount
    ) external view returns (uint256, uint256) {
        uint256 fees = 0;
        uint256 tokensForBurn = 0;

        // On sell
        if (_isSelling && sellTotalFees > 0) {
            fees = _amount.mul(sellTotalFees).div(100);
            tokensForBurn += (fees * sellBurnFee) / sellTotalFees;
        }
        // On buy
        else if (_isBuying && buyTotalFees > 0) {
            fees = _amount.mul(buyTotalFees).div(100);
            tokensForBurn += (fees * buyBurnFee) / buyTotalFees;
        }

        return (fees, tokensForBurn);
    }

    function updateBuyFees(uint256 _burnFee, uint256 _devFee)
        external
        onlyOwner
    {
        buyBurnFee = _burnFee;
        buyDevAndMarketingFee = _devFee;
        buyTotalFees = buyBurnFee + buyDevAndMarketingFee;
        require(buyTotalFees <= 20, "Must keep fees at 20% or less");
    }

    function updateSellFees(uint256 _burnFee, uint256 _devFee)
        external
        onlyOwner
    {
        sellBurnFee = _burnFee;
        sellDevAndMarketingFee = _devFee;
        sellTotalFees = sellBurnFee + sellDevAndMarketingFee;
        require(sellTotalFees <= 25, "Must keep fees at 25% or less");
    }

    function updateFbmAddress(address _newAddr) external onlyOwner {
        fbmContract = IFuckBearMarket(_newAddr);
        fbmAddress = _newAddr;
    }
}