// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "../../features/UsingProvidersAggregator.sol";
import "../../features/UsingMaxDeviation.sol";
import "../../features/UsingStableCoinProvider.sol";
import "../../features/UsingStalePeriod.sol";
import "../../interfaces/periphery/IUpdatableOracle.sol";
import "../../interfaces/core/IUniswapV2LikePriceProvider.sol";

/**
 * @title alUSD Oracle (mainnet-only)
 */
contract AlusdTokenMainnetOracle is
    IUpdatableOracle,
    UsingProvidersAggregator,
    UsingStableCoinProvider,
    UsingStalePeriod
{
    uint256 public constant ONE_ALUSD = 1e18;
    address public constant ALUSD_ADDRESS = 0xBC6DA0FE9aD5f3b0d58160288917AA56653660E9;

    constructor(
        IPriceProvidersAggregator providersAggregator_,
        IStableCoinProvider stableCoinProvider_,
        uint256 stalePeriod_
    )
        UsingProvidersAggregator(providersAggregator_)
        UsingStableCoinProvider(stableCoinProvider_)
        UsingStalePeriod(stalePeriod_)
    {
        require(address(stableCoinProvider_) != address(0), "stable-coin-provider-is-null");
    }

    /// @inheritdoc ITokenOracle
    function getPriceInUsd(address _asset) external view returns (uint256 _priceInUsd) {
        require(address(_asset) == ALUSD_ADDRESS, "invalid-token");

        uint256 _lastUpdatedAt;
        (_priceInUsd, _lastUpdatedAt) = providersAggregator.quoteTokenToUsd(
            DataTypes.Provider.SUSHISWAP,
            ALUSD_ADDRESS,
            ONE_ALUSD
        );

        require(_priceInUsd > 0 && !_priceIsStale(_lastUpdatedAt), "price-invalid");
    }

    /// @inheritdoc IUpdatableOracle
    function update() external override {
        IUniswapV2LikePriceProvider(address(providersAggregator.priceProviders(DataTypes.Provider.SUSHISWAP)))
            .updateOrAdd(ALUSD_ADDRESS, stableCoinProvider.getStableCoinIfPegged());
    }
}