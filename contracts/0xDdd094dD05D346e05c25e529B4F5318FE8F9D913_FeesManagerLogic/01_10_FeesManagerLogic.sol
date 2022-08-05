// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IApollo.sol";


contract FeesManagerLogic is Ownable {
    using SafeMath for uint256;

    uint256 public buyBurnFee;
    uint256 public buyDevFee;
    uint256 public buyTotalFees;

    uint256 public sellBurnFee;
    uint256 public sellDevFee;
    uint256 public sellTotalFees;

    IApollo public apolloContract;
    address public apolloAddress;

    // Main burn and fees algorithm, might change for optimisation
    function estimateFees(
        bool _isSelling,
        bool _isBuying,
        uint256 _amount
    ) external view returns (uint256, uint256) {
        require(_msgSender() == apolloAddress, "Not Apollo contract");

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
        buyDevFee = _devFee;
        buyTotalFees = buyBurnFee + buyDevFee;
        require(buyTotalFees <= 20, "Must keep fees at 20% or less");
    }

    function updateSellFees(uint256 _burnFee, uint256 _devFee)
        external
        onlyOwner
    {
        sellBurnFee = _burnFee;
        sellDevFee = _devFee;
        sellTotalFees = sellBurnFee + sellDevFee;
        require(sellTotalFees <= 25, "Must keep fees at 25% or less");
    }

    function updateApolloAddress(address _newAddr) external onlyOwner {
        apolloContract = IApollo(_newAddr);
        apolloAddress = _newAddr;
    }
}