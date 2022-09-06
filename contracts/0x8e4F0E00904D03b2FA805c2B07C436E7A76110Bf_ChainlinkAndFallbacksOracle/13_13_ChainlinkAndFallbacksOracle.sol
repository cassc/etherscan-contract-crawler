// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../interfaces/core/IPriceProvidersAggregator.sol";
import "../interfaces/periphery/IOracle.sol";
import "../features/UsingProvidersAggregator.sol";
import "../features/UsingMaxDeviation.sol";
import "../features/UsingStalePeriod.sol";

/**
 * @title Chainlink and Fallbacks oracle
 * @dev Uses chainlink as primary oracle, if it doesn't support the asset(s), get price from fallback providers
 */
contract ChainlinkAndFallbacksOracle is IOracle, UsingProvidersAggregator, UsingMaxDeviation, UsingStalePeriod {
    /// @notice The fallback provider A. It's used when Chainlink isn't available
    DataTypes.Provider public fallbackProviderA;

    /// @notice The fallback provider B. It's used when Chainlink isn't available
    /// @dev This is optional
    DataTypes.Provider public fallbackProviderB;

    /// @notice Emitted when fallback providers are updated
    event FallbackProvidersUpdated(
        DataTypes.Provider oldFallbackProviderA,
        DataTypes.Provider newFallbackProviderA,
        DataTypes.Provider oldFallbackProviderB,
        DataTypes.Provider newFallbackProviderB
    );

    constructor(
        IPriceProvidersAggregator providersAggregator_,
        uint256 maxDeviation_,
        uint256 stalePeriod_,
        DataTypes.Provider fallbackProviderA_,
        DataTypes.Provider fallbackProviderB_
    ) UsingProvidersAggregator(providersAggregator_) UsingMaxDeviation(maxDeviation_) UsingStalePeriod(stalePeriod_) {
        require(fallbackProviderA_ != DataTypes.Provider.NONE, "fallback-provider-not-set");
        fallbackProviderA = fallbackProviderA_;
        fallbackProviderB = fallbackProviderB_;
    }

    /// @inheritdoc IOracle
    function getPriceInUsd(address _asset) public view virtual returns (uint256 _priceInUsd) {
        // 1. Get price from chainlink
        uint256 _lastUpdatedAt;
        (_priceInUsd, _lastUpdatedAt) = _getPriceInUsd(DataTypes.Provider.CHAINLINK, _asset);

        // 2. If price from chainlink is OK return it
        if (_priceInUsd > 0 && !_priceIsStale(_lastUpdatedAt)) {
            return _priceInUsd;
        }

        // 3. Get price from fallback A
        (uint256 _amountOutA, uint256 _lastUpdatedAtA) = _getPriceInUsd(fallbackProviderA, _asset);

        // 4. If price from fallback A is OK and there isn't a fallback B, return price from fallback A
        bool _aPriceOK = _amountOutA > 0 && !_priceIsStale(_lastUpdatedAtA);
        if (fallbackProviderB == DataTypes.Provider.NONE) {
            require(_aPriceOK, "fallback-a-failed");
            return _amountOutA;
        }

        // 5. Get price from fallback B
        (uint256 _amountOutB, uint256 _lastUpdatedAtB) = _getPriceInUsd(fallbackProviderB, _asset);

        // 6. If only one price from fallbacks is valid, return it
        bool _bPriceOK = _amountOutB > 0 && !_priceIsStale(_lastUpdatedAtB);
        if (!_bPriceOK && _aPriceOK) {
            return _amountOutA;
        } else if (_bPriceOK && !_aPriceOK) {
            return _amountOutB;
        }

        // 7. Check fallback prices deviation
        require(_aPriceOK && _bPriceOK, "fallbacks-failed");
        require(_isDeviationOK(_amountOutA, _amountOutB), "prices-deviation-too-high");

        // 8. If deviation is OK, return price from fallback A
        return _amountOutA;
    }

    /// @inheritdoc IOracle
    function quote(
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_
    ) public view virtual returns (uint256 _amountOut) {
        // 1. Get price from chainlink
        uint256 _lastUpdatedAt;
        (_amountOut, _lastUpdatedAt) = _quote(DataTypes.Provider.CHAINLINK, tokenIn_, tokenOut_, amountIn_);

        // 2. If price from chainlink is OK return it
        if (_amountOut > 0 && !_priceIsStale(_lastUpdatedAt)) {
            return _amountOut;
        }

        // 3. Get price from fallback A
        (uint256 _amountOutA, uint256 _lastUpdatedAtA) = _quote(fallbackProviderA, tokenIn_, tokenOut_, amountIn_);

        // 4. If price from fallback A is OK and there isn't a fallback B, return price from fallback A
        bool _aPriceOK = _amountOutA > 0 && !_priceIsStale(_lastUpdatedAtA);
        if (fallbackProviderB == DataTypes.Provider.NONE) {
            require(_aPriceOK, "fallback-a-failed");
            return _amountOutA;
        }

        // 5. Get price from fallback B
        (uint256 _amountOutB, uint256 _lastUpdatedAtB) = _quote(fallbackProviderB, tokenIn_, tokenOut_, amountIn_);

        // 6. If only one price from fallbacks is valid, return it
        bool _bPriceOK = _amountOutB > 0 && !_priceIsStale(_lastUpdatedAtB);
        if (!_bPriceOK && _aPriceOK) {
            return _amountOutA;
        } else if (_bPriceOK && !_aPriceOK) {
            return _amountOutB;
        }

        // 7. Check fallback prices deviation
        require(_aPriceOK && _bPriceOK, "fallbacks-failed");
        require(_isDeviationOK(_amountOutA, _amountOutB), "prices-deviation-too-high");

        // 8. If deviation is OK, return price from fallback A
        return _amountOutA;
    }

    /// @inheritdoc IOracle
    function quoteTokenToUsd(address token_, uint256 amountIn_) public view virtual returns (uint256 _amountOut) {
        // 1. Get price from chainlink
        uint256 _lastUpdatedAt;
        (_amountOut, _lastUpdatedAt) = _quoteTokenToUsd(DataTypes.Provider.CHAINLINK, token_, amountIn_);

        // 2. If price from chainlink is OK return it
        if (_amountOut > 0 && !_priceIsStale(_lastUpdatedAt)) {
            return _amountOut;
        }

        // 3. Get price from fallback A
        (uint256 _amountOutA, uint256 _lastUpdatedAtA) = _quoteTokenToUsd(fallbackProviderA, token_, amountIn_);

        // 4. If price from fallback A is OK and there isn't a fallback B, return price from fallback A
        bool _aPriceOK = _amountOutA > 0 && !_priceIsStale(_lastUpdatedAtA);
        if (fallbackProviderB == DataTypes.Provider.NONE) {
            require(_aPriceOK, "fallback-a-failed");
            return _amountOutA;
        }

        // 5. Get price from fallback B
        (uint256 _amountOutB, uint256 _lastUpdatedAtB) = _quoteTokenToUsd(fallbackProviderB, token_, amountIn_);

        // 6. If only one price from fallbacks is valid, return it
        bool _bPriceOK = _amountOutB > 0 && !_priceIsStale(_lastUpdatedAtB);
        if (!_bPriceOK && _aPriceOK) {
            return _amountOutA;
        } else if (_bPriceOK && !_aPriceOK) {
            return _amountOutB;
        }

        // 7. Check fallback prices deviation
        require(_aPriceOK && _bPriceOK, "fallbacks-failed");
        require(_isDeviationOK(_amountOutA, _amountOutB), "prices-deviation-too-high");

        // 8. If deviation is OK, return price from fallback A
        return _amountOutA;
    }

    /// @inheritdoc IOracle
    function quoteUsdToToken(address token_, uint256 amountIn_) public view virtual returns (uint256 _amountOut) {
        // 1. Get price from chainlink
        uint256 _lastUpdatedAt;
        (_amountOut, _lastUpdatedAt) = _quoteUsdToToken(DataTypes.Provider.CHAINLINK, token_, amountIn_);

        // 2. If price from chainlink is OK return it
        if (_amountOut > 0 && !_priceIsStale(_lastUpdatedAt)) {
            return _amountOut;
        }

        // 3. Get price from fallback A
        (uint256 _amountOutA, uint256 _lastUpdatedAtA) = _quoteUsdToToken(fallbackProviderA, token_, amountIn_);

        // 4. If price from fallback A is OK and there isn't a fallback B, return price from fallback A
        bool _aPriceOK = _amountOutA > 0 && !_priceIsStale(_lastUpdatedAtA);
        if (fallbackProviderB == DataTypes.Provider.NONE) {
            require(_aPriceOK, "fallback-a-failed");
            return _amountOutA;
        }

        // 5. Get price from fallback B
        (uint256 _amountOutB, uint256 _lastUpdatedAtB) = _quoteUsdToToken(fallbackProviderB, token_, amountIn_);

        // 6. If only one price from fallbacks is valid, return it
        bool _bPriceOK = _amountOutB > 0 && !_priceIsStale(_lastUpdatedAtB);
        if (!_bPriceOK && _aPriceOK) {
            return _amountOutA;
        } else if (_bPriceOK && !_aPriceOK) {
            return _amountOutB;
        }

        // 7. Check fallback prices deviation
        require(_aPriceOK && _bPriceOK, "fallbacks-failed");
        require(_isDeviationOK(_amountOutA, _amountOutB), "prices-deviation-too-high");

        // 8. If deviation is OK, return price from fallback A
        return _amountOutA;
    }

    /**
     * @notice Wrapped `getPriceInUsd` function
     * @dev Return [0,0] (i.e. invalid quote) if the call reverts
     */
    function _getPriceInUsd(DataTypes.Provider provider_, address token_)
        private
        view
        returns (uint256 _priceInUsd, uint256 _lastUpdatedAt)
    {
        try providersAggregator.getPriceInUsd(provider_, token_) returns (
            uint256 __priceInUsd,
            uint256 __lastUpdatedAt
        ) {
            _priceInUsd = __priceInUsd;
            _lastUpdatedAt = __lastUpdatedAt;
        } catch {}
    }

    /**
     * @notice Wrapped providers aggregator's `quote` function
     * @dev Return [0,0] (i.e. invalid quote) if the call reverts
     */
    function _quote(
        DataTypes.Provider provider_,
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_
    ) private view returns (uint256 _amountOut, uint256 _lastUpdatedAt) {
        try providersAggregator.quote(provider_, tokenIn_, tokenOut_, amountIn_) returns (
            uint256 __amountOut,
            uint256 __lastUpdatedAt
        ) {
            _amountOut = __amountOut;
            _lastUpdatedAt = __lastUpdatedAt;
        } catch {}
    }

    /**
     * @notice Wrapped providers aggregator's `quoteTokenToUsd` function
     * @dev Return [0,0] (i.e. invalid quote) if the call reverts
     */
    function _quoteTokenToUsd(
        DataTypes.Provider provider_,
        address token_,
        uint256 amountIn_
    ) private view returns (uint256 _amountOut, uint256 _lastUpdatedAt) {
        try providersAggregator.quoteTokenToUsd(provider_, token_, amountIn_) returns (
            uint256 __amountOut,
            uint256 __lastUpdatedAt
        ) {
            _amountOut = __amountOut;
            _lastUpdatedAt = __lastUpdatedAt;
        } catch {}
    }

    /**
     * @notice Wrapped providers aggregator's `quoteUsdToToken` function
     * @dev Return [0,0] (i.e. invalid quote) if the call reverts
     */
    function _quoteUsdToToken(
        DataTypes.Provider provider_,
        address token_,
        uint256 amountIn_
    ) private view returns (uint256 _amountOut, uint256 _lastUpdatedAt) {
        try providersAggregator.quoteUsdToToken(provider_, token_, amountIn_) returns (
            uint256 __amountOut,
            uint256 __lastUpdatedAt
        ) {
            _amountOut = __amountOut;
            _lastUpdatedAt = __lastUpdatedAt;
        } catch {}
    }

    /**
     * @notice Update fallback providers
     * @dev The fallback provider B is optional
     */
    function updateFallbackProviders(DataTypes.Provider fallbackProviderA_, DataTypes.Provider fallbackProviderB_)
        external
        onlyGovernor
    {
        require(fallbackProviderA_ != DataTypes.Provider.NONE, "fallback-a-is-null");
        emit FallbackProvidersUpdated(fallbackProviderA, fallbackProviderA_, fallbackProviderB, fallbackProviderB_);
        fallbackProviderA = fallbackProviderA_;
        fallbackProviderB = fallbackProviderB_;
    }
}