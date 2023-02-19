//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./events.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Helpers is Events {
    using SafeERC20 for IERC20;

    modifier nonReentrant() {
        require(_status != 2, "ReentrancyGuard: reentrant call");
        _status = 2;
        _;
        _status = 1;
    }

    /**
     * @dev Helper function to get current eth borrow rate on aave.
     */
    function getWethBorrowRate()
        internal
        view
        returns (uint256 wethBorrowRate_)
    {
        (, , , , wethBorrowRate_, , , , , ) = aaveProtocolDataProvider
            .getReserveData(wethAddr);
    }

    /**
     * @dev Helper function to get current steth collateral on aave.
     */
    function getStEthCollateralAmount()
        internal
        view
        returns (uint256 stEthAmount_)
    {
        stEthAmount_ = astethToken.balanceOf(address(vaultDsa));
    }

    /**
     * @dev Helper function to get current eth debt on aave.
     */
    function getWethDebtAmount()
        internal
        view
        returns (uint256 wethDebtAmount_)
    {
        wethDebtAmount_ = awethVariableDebtToken.balanceOf(address(vaultDsa));
    }

    struct BalVariables {
        uint256 wethVaultBal;
        uint256 wethDsaBal;
        uint256 stethVaultBal;
        uint256 stethDsaBal;
        uint256 totalBal;
    }

    /**
     * @dev Helper function to get ideal eth/steth amount in vault or vault's dsa.
     */
    function getIdealBalances()
        public
        view
        returns (BalVariables memory balances_)
    {
        balances_.wethVaultBal = wethContract.balanceOf(address(this));
        balances_.wethDsaBal = wethContract.balanceOf(address(vaultDsa));
        balances_.stethVaultBal = stEthContract.balanceOf(address(this));
        balances_.stethDsaBal = stEthContract.balanceOf(address(vaultDsa));
        balances_.totalBal =
            balances_.wethVaultBal +
            balances_.wethDsaBal +
            balances_.stethVaultBal +
            balances_.stethDsaBal;
    }

    /**
     * @dev Helper function to get net assets everywhere (not substracting revenue here).
     */
    function netAssets()
        public
        view
        returns (
            uint256 netCollateral_,
            uint256 netBorrow_,
            BalVariables memory balances_,
            uint256 netSupply_,
            uint256 netBal_
        )
    {
        netCollateral_ = getStEthCollateralAmount();
        netBorrow_ = getWethDebtAmount();
        balances_ = getIdealBalances();
        netSupply_ = netCollateral_ + balances_.totalBal;
        netBal_ = netSupply_ - netBorrow_;
    }

    /**
     * @dev Helper function to get current exchange price and new revenue generated.
     */
    function getCurrentExchangePrice()
        public
        view
        returns (uint256 exchangePrice_, uint256 newRevenue_)
    {
        (, , , , uint256 netBal_) = netAssets();
        netBal_ = netBal_ - revenue;
        uint256 totalSupply_ = totalSupply();
        uint256 exchangePriceWithRevenue_;
        if (totalSupply_ != 0) {
            exchangePriceWithRevenue_ = (netBal_ * 1e18) / totalSupply_;
        } else {
            exchangePriceWithRevenue_ = 1e18;
        }
        // Only calculate revenue if there's a profit
        if (exchangePriceWithRevenue_ > lastRevenueExchangePrice) {
            uint256 newProfit_ = netBal_ -
                ((lastRevenueExchangePrice * totalSupply_) / 1e18);
            newRevenue_ = (newProfit_ * revenueFee) / 10000;
            exchangePrice_ = ((netBal_ - newRevenue_) * 1e18) / totalSupply_;
        } else {
            exchangePrice_ = exchangePriceWithRevenue_;
        }
    }

    /**
     * @dev Helper function to validate the safety of aave position after rebalancing.
     */
    function validateFinalRatio()
        internal
        view
        returns (
            bool maxIsOk_,
            bool maxGapIsOk_,
            bool minIsOk_,
            bool minGapIsOk_,
            bool hfIsOk_
        )
    {
        // Not substracting revenue here as it can also help save position.
        (,,,,,uint hf_) = aaveLendingPool.getUserAccountData(address(vaultDsa));
        (
            uint256 netCollateral_,
            uint256 netBorrow_,
            ,
            uint256 netSupply_,

        ) = netAssets();
        uint256 ratioMax_ = (netBorrow_ * 1e4) / netCollateral_; // Aave position ratio should not go above max limit
        maxIsOk_ = ratios.maxLimit > ratioMax_;
        maxGapIsOk_ = ratioMax_ > ratios.maxLimit - 100;
        uint256 ratioMin_ = (netBorrow_ * 1e4) / netSupply_; // net ratio (position + ideal) should not go above min limit
        minIsOk_ = ratios.minLimit > ratioMin_;
        minGapIsOk_ = ratios.minLimitGap < ratioMin_;
        hfIsOk_ = hf_ > 1015 * 1e15; // HF should be more than 1.015 (this will allow ratio to always stay below 74%)
    }

}