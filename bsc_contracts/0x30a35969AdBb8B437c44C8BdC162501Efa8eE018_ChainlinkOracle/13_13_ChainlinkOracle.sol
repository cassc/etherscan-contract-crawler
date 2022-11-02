// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "../interfaces/periphery/IOracle.sol";
import "../features/UsingStalePeriod.sol";

/**
 * @title Chainlink oracle
 */
contract ChainlinkOracle is IOracle, UsingStalePeriod {
    constructor(uint256 stalePeriod_) UsingStalePeriod(stalePeriod_) {}

    /// @inheritdoc IOracle
    function getPriceInUsd(address token_) public view virtual returns (uint256 _priceInUsd) {
        uint256 _lastUpdatedAt;
        (_priceInUsd, _lastUpdatedAt) = addressProvider.providersAggregator().getPriceInUsd(
            DataTypes.Provider.CHAINLINK,
            token_
        );
        require(_priceInUsd > 0 && !_priceIsStale(token_, _lastUpdatedAt), "price-invalid");
    }

    /// @inheritdoc IOracle
    function quote(
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_
    ) public view virtual returns (uint256 _amountOut) {
        uint256 _tokenInLastUpdatedAt;
        uint256 _tokenOutLastUpdatedAt;
        (_amountOut, _tokenInLastUpdatedAt, _tokenOutLastUpdatedAt) = addressProvider.providersAggregator().quote(
            DataTypes.Provider.CHAINLINK,
            tokenIn_,
            tokenOut_,
            amountIn_
        );

        require(
            _amountOut > 0 &&
                !_priceIsStale(tokenIn_, _tokenInLastUpdatedAt) &&
                !_priceIsStale(tokenIn_, _tokenOutLastUpdatedAt),
            "price-invalid"
        );
    }

    /// @inheritdoc IOracle
    function quoteTokenToUsd(address token_, uint256 amountIn_) public view virtual returns (uint256 _amountOut) {
        uint256 _lastUpdatedAt;
        (_amountOut, _lastUpdatedAt) = addressProvider.providersAggregator().quoteTokenToUsd(
            DataTypes.Provider.CHAINLINK,
            token_,
            amountIn_
        );
        require(_amountOut > 0 && !_priceIsStale(token_, _lastUpdatedAt), "price-invalid");
    }

    /// @inheritdoc IOracle
    function quoteUsdToToken(address token_, uint256 amountIn_) public view virtual returns (uint256 _amountOut) {
        uint256 _lastUpdatedAt;
        (_amountOut, _lastUpdatedAt) = addressProvider.providersAggregator().quoteUsdToToken(
            DataTypes.Provider.CHAINLINK,
            token_,
            amountIn_
        );
        require(_amountOut > 0 && !_priceIsStale(token_, _lastUpdatedAt), "price-invalid");
    }
}