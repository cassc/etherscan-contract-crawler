// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
pragma abicoder v2;

import "../../../StatisticsBase.sol";

contract OlaStatistics is StatisticsBase {
    /**
     * @notice get USD price by Venus Oracle for xToken
     * @param xToken xToken address
     * @param comptroller comptroller address
     * @return priceUSD USD price for xToken (decimal = 18 + (18 - decimal of underlying))
     */
    function _getUnderlyingUSDPrice(address xToken, address comptroller)
        internal
        view
        override
        returns (uint256 priceUSD)
    {
        priceUSD = IComptrollerOla(comptroller).getUnderlyingPriceInLen(
            IXToken(xToken).underlying()
        );
    }

    /**
     * @notice get rewards underlying token of startegy
     * @param comptroller comptroller address
     * @return rewardsToken rewards token address
     */
    function _getRewardsToken(address comptroller)
        internal
        view
        override
        returns (address rewardsToken)
    {
        rewardsToken = IDistributionOla(
            IComptrollerOla(comptroller).rainMaker()
        ).lnIncentiveTokenAddress();
    }

    /**
     * @notice get rewards underlying token price
     * @param comptroller comptroller address
     * @param rewardsToken Address of rewards token
     * @return priceUSD usd amount : (decimal = 18 + (18 - decimal of rewards token))
     */
    function _getRewardsTokenPrice(address comptroller, address rewardsToken)
        internal
        view
        override
        returns (uint256 priceUSD)
    {
        priceUSD = IComptrollerOla(comptroller).getUnderlyingPriceInLen(
            rewardsToken
        );
    }

    /**
     * @notice Get Ola earned
     * @param logic Logic contract address
     * @param comptroller comptroller address
     * @return olaEarned
     */
    function _getStrategyEarned(address logic, address comptroller)
        internal
        view
        override
        returns (uint256 olaEarned)
    {
        address[] memory xTokenList = _getAllMarkets(comptroller);
        address rainMaker = IComptrollerOla(comptroller).rainMaker();
        uint256 index;
        olaEarned = 0;

        for (index = 0; index < xTokenList.length; ) {
            address xToken = xTokenList[index];
            uint256 borrowIndex = IXToken(xToken).borrowIndex();
            (uint224 supplyIndex, ) = IDistributionOla(rainMaker)
                .compSupplyState(xToken);
            uint256 supplierIndex = IDistributionOla(rainMaker)
                .compSupplierIndex(xToken, logic);
            (uint224 borrowState, ) = IDistributionOla(rainMaker)
                .compBorrowState(xToken);
            uint256 borrowerIndex = IDistributionOla(rainMaker)
                .compBorrowerIndex(xToken, logic);

            if (supplierIndex == 0 && supplyIndex > 0)
                supplierIndex = IDistributionOla(rainMaker).compInitialIndex();

            olaEarned +=
                (IERC20Upgradeable(xToken).balanceOf(logic) *
                    (supplyIndex - supplierIndex)) /
                10**36;

            if (borrowerIndex > 0) {
                uint256 borrowerAmount = (IXToken(xToken).borrowBalanceStored(
                    logic
                ) * 10**18) / borrowIndex;
                olaEarned +=
                    (borrowerAmount * (borrowState - borrowerIndex)) /
                    10**36;
            }

            unchecked {
                ++index;
            }
        }

        olaEarned += IDistributionOla(rainMaker).compAccrued(logic);

        // Convert to USD using Ola
        olaEarned =
            (olaEarned *
                _getRewardsTokenPrice(
                    comptroller,
                    _getRewardsToken(comptroller)
                )) /
            BASE;
    }

    /**
     * @notice Check xToken is for native token
     * @param xToken Address of xToken
     * @return isXNative true : xToken is for native token
     */
    function _isXNative(address xToken)
        internal
        view
        override
        returns (bool isXNative)
    {
        if (
            IXToken(xToken).underlying() ==
            0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
        ) isXNative = true;
        else isXNative = false;
    }

    /**
     * @notice get collateralFactorMantissa of startegy
     * @param comptroller compotroller address
     * @return collateralFactorMantissa collateralFactorMantissa
     */
    function _getCollateralFactorMantissa(address xToken, address comptroller)
        internal
        view
        override
        returns (uint256 collateralFactorMantissa)
    {
        (, collateralFactorMantissa, , , , ) = IComptrollerOla(comptroller)
            .markets(xToken);
    }

    /**
     * @notice get rewardsSpeed
     * @param _asset Address of asset
     * @param comptroller comptroller address
     */
    function _getRewardsSpeed(address _asset, address comptroller)
        internal
        view
        override
        returns (uint256)
    {
        return
            IDistributionOla(IComptrollerOla(comptroller).rainMaker())
                .compSpeeds(_asset);
    }

    /**
     * @notice get rewardsSupplySpeed
     * @param _asset Address of asset
     * @param comptroller comptroller address
     */
    function _getRewardsSupplySpeed(address _asset, address comptroller)
        internal
        view
        override
        returns (uint256)
    {
        return
            IDistributionOla(IComptrollerOla(comptroller).rainMaker())
                .compSupplySpeeds(_asset);
    }
}