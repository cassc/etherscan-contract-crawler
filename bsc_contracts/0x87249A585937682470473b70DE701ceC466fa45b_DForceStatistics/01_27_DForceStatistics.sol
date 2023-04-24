// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
pragma abicoder v2;

import "../../../StatisticsBase.sol";
import "../../../interfaces/IDForce.sol";

contract DForceStatistics is StatisticsBase {
    using SafeRatioMath for uint256;

    address public swapRouterDF;
    address[] public pathToSwapDFToStableCoin;

    /*** Public Set function ***/

    /**
     * @notice Set DF to StableCoin information
     */
    function setDFSwap(
        address _swapRouterDF,
        address[] calldata _pathToSwapDFToStableCoin
    ) external onlyOwnerAndAdmin {
        require(_pathToSwapDFToStableCoin.length >= 2, "DST1");

        swapRouterDF = _swapRouterDF;
        pathToSwapDFToStableCoin = _pathToSwapDFToStableCoin;
    }

    /*** Public Set function ***/

    /**
     * @notice get USD price by Oracle
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
        address underlying = IXToken(xToken).underlying();
        if (underlying == _getRewardsToken(comptroller)) {
            priceUSD = _getRewardsTokenPrice(comptroller, underlying);
        } else {
            if (priceOracles[underlying] == ZERO_ADDRESS) return 0;

            uint256 decimals = underlying == ZERO_ADDRESS
                ? DECIMALS
                : IERC20MetadataUpgradeable(underlying).decimals();

            priceUSD =
                _getAmountUSDByOracle(underlying, 10**decimals) *
                10**(DECIMALS - decimals);
        }
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
        rewardsToken = IDistributionDForce(
            IComptrollerDForce(comptroller).rewardDistributor()
        ).rewardToken();
    }

    /**
     * @notice get rewards underlying token price
     * @param comptroller comptroller address
     * @param rewardsToken Address of rewards token
     * @return priceUSD usd amount (decimal = 18 + (18 - decimal of rewards token))
     */
    function _getRewardsTokenPrice(address comptroller, address rewardsToken)
        internal
        view
        override
        returns (uint256 priceUSD)
    {
        address dfToken = rewardsToken;
        address tokenOut;
        uint256 amountOut;

        tokenOut = pathToSwapDFToStableCoin[
            pathToSwapDFToStableCoin.length - 1
        ];
        amountOut = ISwapGateway(swapGateway).quoteExactInput(
            swapRouterDF,
            10**IERC20MetadataUpgradeable(dfToken).decimals(),
            pathToSwapDFToStableCoin
        );
        priceUSD =
            _getAmountUSDByOracle(tokenOut, amountOut) *
            (10**(DECIMALS - IERC20MetadataUpgradeable(dfToken).decimals()));
    }

    /**
     * @notice Get DForce earned
     * @param logic Logic contract address
     * @param comptroller comptroller address
     * @return dforceEarned
     */
    function _getStrategyEarned(address logic, address comptroller)
        internal
        view
        override
        returns (uint256 dforceEarned)
    {
        address[] memory xTokenList = _getAllMarkets(comptroller);
        IDistributionDForce rewardDistributor = IDistributionDForce(
            IComptrollerDForce(comptroller).rewardDistributor()
        );
        uint256 index;

        uint256 deltaBorrowRewardAmount = 0;
        uint256 deltaSupplyRewardAmount = 0;

        for (index = 0; index < xTokenList.length; ) {
            address xToken = xTokenList[index];
            deltaBorrowRewardAmount += getEarnedDeltaAmount(
                xToken,
                logic,
                rewardDistributor,
                true
            );
            deltaSupplyRewardAmount += getEarnedDeltaAmount(
                xToken,
                logic,
                rewardDistributor,
                false
            );

            unchecked {
                ++index;
            }
        }

        dforceEarned =
            ((rewardDistributor.reward(logic) +
                deltaBorrowRewardAmount +
                deltaSupplyRewardAmount) *
                _getRewardsTokenPrice(
                    comptroller,
                    _getRewardsToken(comptroller)
                )) /
            BASE;
    }

    // https://github.com/dforce-network/LendingContractsV2/blob/master/contracts/RewardDistributorV3.sol#L406
    /**
     * @notice Calculates delta of actual and stored earns
     * @param _asset iToken address
     * @param _logic Logic contract address
     * @param _rewardDistributor DForce rewards destributor contract
     * @param _isBorrow Should calculate delta of earns for borrow or for supply
     * @return delta of actual and stored earns
     */
    function getEarnedDeltaAmount(
        address _asset,
        address _logic,
        IDistributionDForce _rewardDistributor,
        bool _isBorrow
    ) private view returns (uint256) {
        uint256 assetIndex;
        uint256 accountIndex;
        uint256 accountBalance;

        if (_isBorrow) {
            (assetIndex, ) = _rewardDistributor.distributionBorrowState(_asset);
            accountIndex = _rewardDistributor.distributionBorrowerIndex(
                _asset,
                _logic
            );
            accountBalance = IXToken(_asset).borrowBalanceStored(_logic).rdiv(
                IXToken(_asset).borrowIndex()
            );
        } else {
            (assetIndex, ) = _rewardDistributor.distributionSupplyState(_asset);
            accountIndex = _rewardDistributor.distributionSupplierIndex(
                _asset,
                _logic
            );
            accountBalance = IERC20Upgradeable(_asset).balanceOf(_logic);
        }

        uint256 deltaIndex = assetIndex - accountIndex;

        return accountBalance.rmul(deltaIndex);
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
        if (IXToken(xToken).underlying() == ZERO_ADDRESS) isXNative = true;
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
        (collateralFactorMantissa, , , , , , ) = IComptrollerDForce(comptroller)
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
            IDistributionDForce(
                IComptrollerDForce(comptroller).rewardDistributor()
            ).distributionSpeed(_asset);
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
            IDistributionDForce(
                IComptrollerDForce(comptroller).rewardDistributor()
            ).distributionSupplySpeed(_asset);
    }

    function _getAllMarkets(address comptroller)
        internal
        view
        override
        returns (address[] memory)
    {
        return IComptrollerDForce(comptroller).getAlliTokens();
    }

    function _getAccountSnapshot(address xToken, address logic)
        internal
        view
        override
        returns (
            uint256 balance,
            uint256 borrowAmount,
            uint256 mantissa
        )
    {
        balance = IXToken(xToken).balanceOf(logic);
        borrowAmount = IXToken(xToken).borrowBalanceStored(logic);
        mantissa = IXToken(xToken).exchangeRateStored();
    }

    function isXToken(address _asset) public view override returns (bool) {
        return IiToken(_asset).isiToken();
    }
}