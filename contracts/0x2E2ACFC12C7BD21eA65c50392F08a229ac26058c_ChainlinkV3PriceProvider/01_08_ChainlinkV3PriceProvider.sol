// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "../PriceProvider.sol";
import "../IERC20LikeV2.sol";

contract ChainlinkV3PriceProvider is PriceProvider {
    using SafeMath for uint256;

    struct AssetData {
        // Time threshold to invalidate stale prices
        uint256 heartbeat;
        // If true, we bypass the aggregator and consult the fallback provider directly
        bool forceFallback;
        // If true, the aggregator returns price in USD, so we need to convert to QUOTE
        bool convertToQuote;
        // Chainlink aggregator proxy
        AggregatorV3Interface aggregator;
        // Provider used if the aggregator's price is invalid or if it became disabled
        IPriceProvider fallbackProvider;
    }

    /// @dev Aggregator that converts from USD to quote token
    AggregatorV3Interface internal immutable _QUOTE_AGGREGATOR; // solhint-disable-line var-name-mixedcase

    /// @dev Decimals used by the _QUOTE_AGGREGATOR
    uint8 internal immutable _QUOTE_AGGREGATOR_DECIMALS; // solhint-disable-line var-name-mixedcase

    /// @dev Used to optimize calculations in emergency disable function
    // solhint-disable-next-line var-name-mixedcase
    uint256 internal immutable _MAX_PRICE_DIFF = type(uint256).max / (100 * EMERGENCY_PRECISION);
    
    // @dev Precision to use for the EMERGENCY_THRESHOLD
    uint256 public constant EMERGENCY_PRECISION = 1e6;

    /// @dev Disable the aggregator if the difference with the fallback is higher than this percentage (10%)
    uint256 public constant EMERGENCY_THRESHOLD = 10 * EMERGENCY_PRECISION; // solhint-disable-line var-name-mixedcase

    /// @dev this is basically `PriceProvider.quoteToken.decimals()`
    uint8 internal immutable _QUOTE_TOKEN_DECIMALS; // solhint-disable-line var-name-mixedcase

    /// @dev Address allowed to call the emergencyDisable function, can be set by the owner
    address public emergencyManager;

    /// @dev Threshold used to determine if the price returned by the _QUOTE_AGGREGATOR is valid
    uint256 public quoteAggregatorHeartbeat;

    /// @dev Data used for each asset
    mapping(address => AssetData) public assetData;

    event NewAggregator(address indexed asset, AggregatorV3Interface indexed aggregator, bool convertToQuote);
    event NewFallbackPriceProvider(address indexed asset, IPriceProvider indexed fallbackProvider);
    event NewHeartbeat(address indexed asset, uint256 heartbeat);
    event NewQuoteAggregatorHeartbeat(uint256 heartbeat);
    event NewEmergencyManager(address indexed emergencyManager);
    event AggregatorDisabled(address indexed asset, AggregatorV3Interface indexed aggregator);

    error AggregatorDidNotChange();
    error AggregatorPriceNotAvailable();
    error AssetNotSupported();
    error EmergencyManagerDidNotChange();
    error EmergencyThresholdNotReached();
    error FallbackProviderAlreadySet();
    error FallbackProviderDidNotChange();
    error FallbackProviderNotSet();
    error HeartbeatDidNotChange();
    error InvalidAggregator();
    error InvalidAggregatorDecimals();
    error InvalidFallbackPriceProvider();
    error InvalidHeartbeat();
    error OnlyEmergencyManager();
    error QuoteAggregatorHeartbeatDidNotChange();

    modifier onlyAssetSupported(address _asset) {
        if (!assetSupported(_asset)) {
            revert AssetNotSupported();
        }

        _;
    }

    constructor(
        IPriceProvidersRepository _priceProvidersRepository,
        address _emergencyManager,
        AggregatorV3Interface _quoteAggregator,
        uint256 _quoteAggregatorHeartbeat
    ) PriceProvider(_priceProvidersRepository) {
        _setEmergencyManager(_emergencyManager);
        _QUOTE_TOKEN_DECIMALS = IERC20LikeV2(quoteToken).decimals();
        _QUOTE_AGGREGATOR = _quoteAggregator;
        _QUOTE_AGGREGATOR_DECIMALS = _quoteAggregator.decimals();
        quoteAggregatorHeartbeat = _quoteAggregatorHeartbeat;
    }

    /// @inheritdoc IPriceProvider
    function assetSupported(address _asset) public view virtual override returns (bool) {
        AssetData storage data = assetData[_asset];

        // Asset is supported if:
        //     - the asset is the quote token
        //       OR
        //     - the aggregator address is defined AND
        //         - the aggregator is not disabled
        //           OR
        //         - the fallback is defined

        if (_asset == quoteToken) {
            return true;
        }

        if (address(data.aggregator) != address(0)) {
            return !data.forceFallback || address(data.fallbackProvider) != address(0);
        }

        return false;
    }

    /// @dev Returns price directly from aggregator using all internal settings except fallback
    /// @param _asset Asset for which we want to get the price
    function getAggregatorPrice(address _asset) public view virtual returns (bool success, uint256 price) {
        return _getAggregatorPrice(_asset);
    }
    
    /// @inheritdoc IPriceProvider
    function getPrice(address _asset) public view virtual override returns (uint256) {
        address quote = quoteToken;

        if (_asset == quote) {
            return 10 ** _QUOTE_TOKEN_DECIMALS;
        }

        (bool success, uint256 price) = _getAggregatorPrice(_asset);

        return success ? price : _getFallbackPrice(_asset);
    }

    /// @dev Sets the aggregator, fallbackProvider and heartbeat for an asset. Can only be called by the manager.
    /// @param _asset Asset to setup
    /// @param _aggregator Chainlink aggregator proxy
    /// @param _fallbackProvider Provider to use if the price is invalid or if the aggregator was disabled
    /// @param _heartbeat Threshold in seconds to invalidate a stale price
    function setupAsset(
        address _asset,
        AggregatorV3Interface _aggregator,
        IPriceProvider _fallbackProvider,
        uint256 _heartbeat,
        bool _convertToQuote
    ) external virtual onlyManager {
        // This has to be done first so that `_setAggregator` works
        _setHeartbeat(_asset, _heartbeat);

        if (!_setAggregator(_asset, _aggregator, _convertToQuote)) revert AggregatorDidNotChange();

        // We don't care if this doesn't change
        _setFallbackPriceProvider(_asset, _fallbackProvider);
    }

    /// @dev Sets the aggregator for an asset. Can only be called by the manager.
    /// @param _asset Asset for which to set the aggregator
    /// @param _aggregator Aggregator to set
    function setAggregator(address _asset, AggregatorV3Interface _aggregator, bool _convertToQuote)
        external
        virtual
        onlyManager
        onlyAssetSupported(_asset)
    {
        if (!_setAggregator(_asset, _aggregator, _convertToQuote)) revert AggregatorDidNotChange();
    }

    /// @dev Sets the fallback provider for an asset. Can only be called by the manager.
    /// @param _asset Asset for which to set the fallback provider
    /// @param _fallbackProvider Provider to set
    function setFallbackPriceProvider(address _asset, IPriceProvider _fallbackProvider)
        external
        virtual
        onlyManager
        onlyAssetSupported(_asset)
    {
        if (!_setFallbackPriceProvider(_asset, _fallbackProvider)) {
            revert FallbackProviderDidNotChange();
        }
    }

    /// @dev Sets the heartbeat threshold for an asset. Can only be called by the manager.
    /// @param _asset Asset for which to set the heartbeat threshold
    /// @param _heartbeat Threshold to set
    function setHeartbeat(address _asset, uint256 _heartbeat)
        external
        virtual
        onlyManager
        onlyAssetSupported(_asset)
    {
        if (!_setHeartbeat(_asset, _heartbeat)) revert HeartbeatDidNotChange();
    }

    /// @dev Sets the quote aggregator heartbeat threshold. Can only be called by the manager.
    /// @param _heartbeat Threshold to set
    function setQuoteAggregatorHeartbeat(uint256 _heartbeat)
        external
        virtual
        onlyManager
    {
        if (!_setQuoteAggregatorHeartbeat(_heartbeat)) revert QuoteAggregatorHeartbeatDidNotChange();
    }

    /// @dev Sets the emergencyManager. Can only be called by the manager.
    /// @param _emergencyManager Emergency manager to set
    function setEmergencyManager(address _emergencyManager) external virtual onlyManager {
        if (!_setEmergencyManager(_emergencyManager)) revert EmergencyManagerDidNotChange();
    }

    /// @dev Disables the aggregator for an asset if there is a big discrepancy between the aggregator and the
    /// fallback provider. The only way to reenable the asset is by calling setupAsset or setAggregator again.
    /// Can only be called by the emergencyManager.
    /// @param _asset Asset for which to disable the aggregator
    function emergencyDisable(address _asset) external virtual {
        if (msg.sender != emergencyManager) {
            revert OnlyEmergencyManager();
        }

        (bool success, uint256 price) = _getAggregatorPrice(_asset);

        if (!success) {
            revert AggregatorPriceNotAvailable();
        }

        uint256 fallbackPrice = _getFallbackPrice(_asset);

        uint256 diff;

        unchecked {
            // It is ok to uncheck because of the initial fallbackPrice >= price check
            diff = fallbackPrice >= price ? fallbackPrice - price : price - fallbackPrice;
        }

        if (diff > _MAX_PRICE_DIFF || (diff * 100 * EMERGENCY_PRECISION) / price < EMERGENCY_THRESHOLD) {
            revert EmergencyThresholdNotReached();
        }

        // Disable main aggregator, fallback stays enabled
        assetData[_asset].forceFallback = true;

        emit AggregatorDisabled(_asset, assetData[_asset].aggregator);
    }

    function getFallbackProvider(address _asset) external view virtual returns (IPriceProvider) {
        return assetData[_asset].fallbackProvider;
    }

    function _getAggregatorPrice(address _asset) internal view virtual returns (bool success, uint256 price) {
        AssetData storage data = assetData[_asset];

        uint256 heartbeat = data.heartbeat;
        bool forceFallback = data.forceFallback;
        AggregatorV3Interface aggregator = data.aggregator;

        if (address(aggregator) == address(0)) revert AssetNotSupported();

        (
            /*uint80 roundID*/,
            int256 aggregatorPrice,
            /*uint256 startedAt*/,
            uint256 timestamp,
            /*uint80 answeredInRound*/
        ) = aggregator.latestRoundData();

        // If a valid price is returned and it was updated recently
        if (!forceFallback && _isValidPrice(aggregatorPrice, timestamp, heartbeat)) {
            uint256 result;

            if (data.convertToQuote) {
                // _toQuote performs decimal normalization internally
                result = _toQuote(uint256(aggregatorPrice));
            } else {
                uint8 aggregatorDecimals = aggregator.decimals();
                result = _normalizeWithDecimals(uint256(aggregatorPrice), aggregatorDecimals);
            }

            return (true, result);
        }

        return (false, 0);
    }

    function _getFallbackPrice(address _asset) internal view virtual returns (uint256) {
        IPriceProvider fallbackProvider = assetData[_asset].fallbackProvider;

        if (address(fallbackProvider) == address(0)) revert FallbackProviderNotSet();

        return fallbackProvider.getPrice(_asset);
    }

    function _setEmergencyManager(address _emergencyManager) internal virtual returns (bool changed) {
        if (_emergencyManager == emergencyManager) {
            return false;
        }

        emergencyManager = _emergencyManager;

        emit NewEmergencyManager(_emergencyManager);

        return true;
    }

    function _setAggregator(
        address _asset,
        AggregatorV3Interface _aggregator,
        bool _convertToQuote
    ) internal virtual returns (bool changed) {
        if (address(_aggregator) == address(0)) revert InvalidAggregator();

        AssetData storage data = assetData[_asset];

        if (data.aggregator == _aggregator && data.forceFallback == false) {
            return false;
        }

        // There doesn't seem to be a way to verify if this is a "valid" aggregator (other than getting the price)
        data.forceFallback = false;
        data.aggregator = _aggregator;

        (bool success,) = _getAggregatorPrice(_asset);

        if (!success) revert AggregatorPriceNotAvailable();

        if (_convertToQuote && _aggregator.decimals() != _QUOTE_AGGREGATOR_DECIMALS) {
            revert InvalidAggregatorDecimals();
        }

        // We want to always update this
        assetData[_asset].convertToQuote = _convertToQuote;

        emit NewAggregator(_asset, _aggregator, _convertToQuote);

        return true;
    }

    function _setFallbackPriceProvider(address _asset, IPriceProvider _fallbackProvider)
        internal
        virtual
        returns (bool changed)
    {
        if (_fallbackProvider == assetData[_asset].fallbackProvider) {
            return false;
        }

        assetData[_asset].fallbackProvider = _fallbackProvider;

        if (address(_fallbackProvider) != address(0)) {
            if (
                !priceProvidersRepository.isPriceProvider(_fallbackProvider) ||
                !_fallbackProvider.assetSupported(_asset) ||
                _fallbackProvider.quoteToken() != quoteToken
            ) {
                revert InvalidFallbackPriceProvider();
            }

            // Make sure it doesn't revert
            _getFallbackPrice(_asset);
        }

        emit NewFallbackPriceProvider(_asset, _fallbackProvider);

        return true;
    }

    function _setHeartbeat(address _asset, uint256 _heartbeat) internal virtual returns (bool changed) {
        // Arbitrary limit, Chainlink's threshold is always less than a day
        if (_heartbeat > 2 days) revert InvalidHeartbeat();

        if (_heartbeat == assetData[_asset].heartbeat) {
            return false;
        }

        assetData[_asset].heartbeat = _heartbeat;

        emit NewHeartbeat(_asset, _heartbeat);

        return true;
    }

    function _setQuoteAggregatorHeartbeat(uint256 _heartbeat) internal virtual returns (bool changed) {
        // Arbitrary limit, Chainlink's threshold is always less than a day
        if (_heartbeat > 2 days) revert InvalidHeartbeat();

        if (_heartbeat == quoteAggregatorHeartbeat) {
            return false;
        }

        quoteAggregatorHeartbeat = _heartbeat;

        emit NewQuoteAggregatorHeartbeat(_heartbeat);

        return true;
    }

    /// @dev Adjusts the given price to use the same decimals as the quote token.
    /// @param _price Price to adjust decimals
    /// @param _decimals Decimals considered in `_price`
    function _normalizeWithDecimals(uint256 _price, uint8 _decimals) internal view virtual returns (uint256) {
        // We want to return the price of 1 asset token, but with the decimals of the quote token
        if (_QUOTE_TOKEN_DECIMALS == _decimals) {
            return _price;
        } else if (_QUOTE_TOKEN_DECIMALS < _decimals) {
            return _price / 10 ** (_decimals - _QUOTE_TOKEN_DECIMALS);
        } else {
            return _price * 10 ** (_QUOTE_TOKEN_DECIMALS - _decimals);
        }
    }

    /// @dev Converts a price returned by an aggregator to quote units
    function _toQuote(uint256 _price) internal view virtual returns (uint256) {
       (
            /*uint80 roundID*/,
            int256 aggregatorPrice,
            /*uint256 startedAt*/,
            uint256 timestamp,
            /*uint80 answeredInRound*/
        ) = _QUOTE_AGGREGATOR.latestRoundData();

        // If an invalid price is returned
        if (!_isValidPrice(aggregatorPrice, timestamp, quoteAggregatorHeartbeat)) {
            revert AggregatorPriceNotAvailable();
        }

        // _price and aggregatorPrice should both have the same decimals so we normalize here
        return _price * 10 ** _QUOTE_TOKEN_DECIMALS / uint256(aggregatorPrice);
    }

    function _isValidPrice(int256 _price, uint256 _timestamp, uint256 _heartbeat) internal view virtual returns (bool) {
        return _price > 0 && block.timestamp - _timestamp < _heartbeat;
    }
}