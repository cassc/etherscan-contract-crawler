//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../common/variables.sol";
import "hardhat/console.sol";

contract ValidatePositionTestModule is Variables {
    /**
     * @dev reentrancy gaurd.
     */
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
            .getReserveData(address(wethContract));
    }

    /**
     * @dev Helper function to get current token collateral on aave.
     */
    function getTokenCollateralAmount()
        internal
        view
        returns (uint256 tokenAmount_)
    {
        tokenAmount_ = _atoken.balanceOf(address(_vaultDsa));
    }

    /**
     * @dev Helper function to get current steth collateral on aave.
     */
    function getStethCollateralAmount()
        internal
        view
        returns (uint256 stEthAmount_)
    {
        stEthAmount_ = astethToken.balanceOf(address(_vaultDsa));
    }

    /**
     * @dev Helper function to get current eth debt on aave.
     */
    function getWethDebtAmount()
        internal
        view
        returns (uint256 wethDebtAmount_)
    {
        wethDebtAmount_ = awethVariableDebtToken.balanceOf(address(_vaultDsa));
    }

    /**
     * @dev Helper function to token balances of everywhere.
     */
    function getVaultBalances()
        public
        view
        returns (
            uint256 tokenCollateralAmt_,
            uint256 stethCollateralAmt_,
            uint256 wethDebtAmt_,
            uint256 tokenVaultBal_,
            uint256 tokenDSABal_,
            uint256 netTokenBal_
        )
    {
        tokenCollateralAmt_ = getTokenCollateralAmount();
        stethCollateralAmt_ = getStethCollateralAmount();
        wethDebtAmt_ = getWethDebtAmount();
        tokenVaultBal_ = _token.balanceOf(address(this));
        tokenDSABal_ = _token.balanceOf(address(_vaultDsa));
        netTokenBal_ = tokenCollateralAmt_ + tokenVaultBal_ + tokenDSABal_;
    }

    struct ValidateFinalPosition {
        uint256 tokenPriceInBaseCurrency_;
        uint256 ethPriceInBaseCurrency_;
        uint256 excessDebtInBaseCurrency_;
        uint256 netTokenColInBaseCurrency_;
        uint256 netTokenSupplyInBaseCurrency_;
        uint256 ratioMax_;
        uint256 ratioMin_;
    }

    /**
     * @dev Helper function to validate the safety of aave position after rebalancing.
     */
    function validateFinalPosition()
        public
        view
        returns (
            bool criticalIsOk_,
            bool criticalGapIsOk_,
            bool minIsOk_,
            bool minGapIsOk_
        )
    {
        (
            uint256 tokenColAmt_,
            uint256 stethColAmt_,
            uint256 wethDebt_,
            ,
            ,
            uint256 netTokenBal_
        ) = getVaultBalances();

        uint256 ethCoveringDebt_ = (stethColAmt_ * _ratios.stEthLimit) / 10000;

        uint256 excessDebt_ = ethCoveringDebt_ < wethDebt_
            ? wethDebt_ - ethCoveringDebt_
            : 0;

        if (excessDebt_ > 0) {
            // TODO: add a fallback oracle fetching price from chainlink in case Aave changes oracle in future or in Aave v3?
            IAavePriceOracle aaveOracle_ = IAavePriceOracle(
                aaveAddressProvider.getPriceOracle()
            );

            ValidateFinalPosition memory validateFinalPosition_;
            validateFinalPosition_.tokenPriceInBaseCurrency_ = aaveOracle_.getAssetPrice(
                address(_token)
            );
            console.log("Token Price In BaseCurrency", validateFinalPosition_.tokenPriceInBaseCurrency_);
            validateFinalPosition_.ethPriceInBaseCurrency_ = aaveOracle_.getAssetPrice(
                address(wethContract)
            );
            console.log("ETH Price In BaseCurrency", validateFinalPosition_.ethPriceInBaseCurrency_);

            validateFinalPosition_.excessDebtInBaseCurrency_ = (excessDebt_ *
                validateFinalPosition_.ethPriceInBaseCurrency_) / 1e18;

            validateFinalPosition_.netTokenColInBaseCurrency_ = 
                (
                    tokenColAmt_ * validateFinalPosition_.tokenPriceInBaseCurrency_
                ) / (10**_tokenDecimals);

            validateFinalPosition_.netTokenSupplyInBaseCurrency_ = 
                (
                    netTokenBal_ * validateFinalPosition_.tokenPriceInBaseCurrency_
                ) / (10**_tokenDecimals);

            validateFinalPosition_.ratioMax_ = 
                (validateFinalPosition_.excessDebtInBaseCurrency_ * 10000) /
                    validateFinalPosition_.netTokenColInBaseCurrency_;

            validateFinalPosition_.ratioMin_ = 
                (validateFinalPosition_.excessDebtInBaseCurrency_ * 10000) /
                validateFinalPosition_.netTokenSupplyInBaseCurrency_;

            criticalIsOk_ = validateFinalPosition_.ratioMax_ < _ratios.maxLimit;
            criticalGapIsOk_ = validateFinalPosition_.ratioMax_ > _ratios.maxLimitGap;
            minIsOk_ = validateFinalPosition_.ratioMin_ < _ratios.minLimit;
            minGapIsOk_ = validateFinalPosition_.ratioMin_ > _ratios.minLimitGap;
            console.log("Ratio Max", validateFinalPosition_.ratioMax_);
            console.log("Ratio Min", validateFinalPosition_.ratioMin_);
        } else {
            criticalIsOk_ = true;
            minIsOk_ = true;
        }
    }


    /**
     * @dev Helper function to validate the safety of aave position after rebalancing.
     */
    function validateFinalPositionOld()
        public
        view
        returns (
            bool criticalIsOk_,
            bool criticalGapIsOk_,
            bool minIsOk_,
            bool minGapIsOk_
        )
    {
        (
            uint256 tokenColAmt_,
            uint256 stethColAmt_,
            uint256 wethDebt_,
            ,
            ,
            uint256 netTokenBal_
        ) = getVaultBalances();

        uint256 ethCoveringDebt_ = (stethColAmt_ * _ratios.stEthLimit) / 10000;

        uint256 excessDebt_ = ethCoveringDebt_ < wethDebt_
            ? wethDebt_ - ethCoveringDebt_
            : 0;

        if (excessDebt_ > 0) {
            // TODO: add a fallback oracle fetching price from chainlink in case Aave changes oracle in future or in Aave v3?
            uint256 tokenPriceInEth_ = IAavePriceOracle(
                aaveAddressProvider.getPriceOracle()
            ).getAssetPrice(address(_token));
            console.log("Token Price In ETH", tokenPriceInEth_);



            uint256 netTokenColInEth_ = (tokenColAmt_ * tokenPriceInEth_) /
                (10**_tokenDecimals);
            uint256 netTokenSupplyInEth_ = (netTokenBal_ * tokenPriceInEth_) /
                (10**_tokenDecimals);

            uint256 ratioMax_ = (excessDebt_ * 10000) / netTokenColInEth_;
            uint256 ratioMin_ = (excessDebt_ * 10000) / netTokenSupplyInEth_;

            criticalIsOk_ = ratioMax_ < _ratios.maxLimit;
            criticalGapIsOk_ = ratioMax_ > _ratios.maxLimitGap;
            minIsOk_ = ratioMin_ < _ratios.minLimit;
            minGapIsOk_ = ratioMin_ > _ratios.minLimitGap;
            console.log("Ratio Max", ratioMax_);
            console.log("Ratio Min", ratioMin_);
        } else {
            criticalIsOk_ = true;
            minIsOk_ = true;
        }
    }
}