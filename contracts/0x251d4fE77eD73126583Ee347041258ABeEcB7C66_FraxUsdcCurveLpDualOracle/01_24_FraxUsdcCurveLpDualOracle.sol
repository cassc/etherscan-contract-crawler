// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ==================== FraxUsdcCurveLpDualOracle =====================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Author
// Drake Evans: https://github.com/DrakeEvans

// Reviewers
// Dennis: https://github.com/denett

// ====================================================================
import { Timelock2Step } from "frax-std/access-control/v1/Timelock2Step.sol";
import { ITimelock2Step } from "frax-std/access-control/v1/interfaces/ITimelock2Step.sol";
import {
    CurvePoolVirtualPriceOracleWithMinMax,
    ConstructorParams as CurvePoolVirtualPriceOracleWithMinMaxParams
} from "./abstracts/CurvePoolVirtualPriceOracleWithMinMax.sol";
import {
    FraxUsdChainlinkOracleWithMaxDelay,
    ConstructorParams as FraxUsdChainlinkOracleWithMaxDelayParams
} from "./abstracts/FraxUsdChainlinkOracleWithMaxDelay.sol";
import {
    ChainlinkOracleWithMaxDelay,
    ConstructorParams as ChainlinkOracleWithMaxDelayParams
} from "./abstracts/ChainlinkOracleWithMaxDelay.sol";
import {
    FraxUsdcUniswapV3SingleTwapOracle,
    ConstructorParams as FraxUsdcUniswapV3SingleTwapOracleParams
} from "./abstracts/FraxUsdcUniswapV3SingleTwapOracle.sol";
import {
    EthUsdChainlinkOracleWithMaxDelay,
    ConstructorParams as EthUsdChainlinkOracleWithMaxDelayParams
} from "./abstracts/EthUsdChainlinkOracleWithMaxDelay.sol";
import {
    UniswapV3SingleTwapOracle,
    ConstructorParams as UniswapV3SingleTwapOracleParams
} from "./abstracts/UniswapV3SingleTwapOracle.sol";
import { DualOracleBase, ConstructorParams as DualOracleBaseParams } from "./DualOracleBase.sol";
import { IDualOracle } from "interfaces/IDualOracle.sol";

struct ConstructorParams {
    address timelockAddress;
    address fraxErc20;
    uint8 fraxErc20Decimals;
    address usdcErc20;
    uint8 usdcErc20Decimals;
    address wethErc20;
    uint8 wethErc20Decimals;
    address fraxUsdcCurveLpErc20;
    uint8 fraxUsdcCurveLpErc20Decimals;
    // =
    address baseToken0;
    uint8 baseToken0Decimals;
    address quoteToken0;
    uint8 quoteToken0Decimals;
    address baseToken1;
    uint8 baseToken1Decimals;
    address quoteToken1;
    uint8 quoteToken1Decimals;
    // =
    address usdcUsdChainlinkFeedAddress;
    uint256 usdUsdcChainlinkMaximumOracleDelay;
    // =
    address fraxUsdChainlinkFeedAddress;
    uint256 fraxUsdMaximumOracleDelay;
    // =
    address curvePoolVirtualPriceAddress;
    uint256 minimumCurvePoolVirtualPrice;
    uint256 maximumCurvePoolVirtualPrice;
    // =
    address fraxUsdcUniswapV3PairAddress;
    uint32 fraxUsdcTwapDuration;
    address fraxUsdcTwapBaseToken;
    address fraxUsdcTwapQuoteToken;
}

/// @title FraxUsdcCurveLpDualOracle
/// @author Drake Evans (Frax Finance) https://github.com/drakeevans
/// @notice  An oracle for Frax/USDC Curve LP tokens
contract FraxUsdcCurveLpDualOracle is
    Timelock2Step,
    DualOracleBase,
    CurvePoolVirtualPriceOracleWithMinMax,
    FraxUsdChainlinkOracleWithMaxDelay,
    ChainlinkOracleWithMaxDelay,
    FraxUsdcUniswapV3SingleTwapOracle
{
    uint8 public immutable FRAX_ERC20_DECIMALS;
    uint256 public immutable FRAX_ERC20_PRECISION;
    uint8 public immutable USDC_ERC20_DECIMALS;
    uint256 public immutable USDC_ERC20_PRECISION;
    uint8 public immutable FRAX_USDC_CURVE_POOL_LP_ERC20_DECIMALS;
    uint256 public immutable FRAX_USDC_CURVE_POOL_LP_ERC20_PRECISION;
    uint256 public immutable USDC_TO_FRAX_NORMALIZATION;

    constructor(
        ConstructorParams memory _params
    )
        Timelock2Step()
        DualOracleBase(
            DualOracleBaseParams({
                baseToken0: _params.baseToken0,
                baseToken0Decimals: _params.baseToken0Decimals,
                quoteToken0: _params.quoteToken0,
                quoteToken0Decimals: _params.quoteToken0Decimals,
                baseToken1: _params.baseToken1,
                baseToken1Decimals: _params.baseToken1Decimals,
                quoteToken1: _params.quoteToken1,
                quoteToken1Decimals: _params.quoteToken1Decimals
            })
        )
        CurvePoolVirtualPriceOracleWithMinMax(
            CurvePoolVirtualPriceOracleWithMinMaxParams({
                curvePoolVirtualPriceAddress: _params.curvePoolVirtualPriceAddress,
                minimumCurvePoolVirtualPrice: _params.minimumCurvePoolVirtualPrice,
                maximumCurvePoolVirtualPrice: _params.maximumCurvePoolVirtualPrice
            })
        )
        FraxUsdChainlinkOracleWithMaxDelay(
            FraxUsdChainlinkOracleWithMaxDelayParams({
                fraxUsdChainlinkFeedAddress: _params.fraxUsdChainlinkFeedAddress,
                fraxUsdMaximumOracleDelay: _params.fraxUsdMaximumOracleDelay
            })
        )
        ChainlinkOracleWithMaxDelay(
            ChainlinkOracleWithMaxDelayParams({
                chainlinkFeedAddress: _params.usdcUsdChainlinkFeedAddress,
                maximumOracleDelay: _params.usdUsdcChainlinkMaximumOracleDelay
            })
        )
        FraxUsdcUniswapV3SingleTwapOracle(
            FraxUsdcUniswapV3SingleTwapOracleParams({
                fraxUsdcUniswapV3PairAddress: _params.fraxUsdcUniswapV3PairAddress,
                fraxUsdcTwapDuration: _params.fraxUsdcTwapDuration,
                fraxUsdcTwapBaseToken: _params.fraxUsdcTwapBaseToken,
                fraxUsdcTwapQuoteToken: _params.fraxUsdcTwapQuoteToken
            })
        )
    {
        _setTimelock({ _newTimelock: _params.timelockAddress });
        _registerInterface({ interfaceId: type(IDualOracle).interfaceId });
        _registerInterface({ interfaceId: type(ITimelock2Step).interfaceId });

        FRAX_ERC20_DECIMALS = _params.fraxErc20Decimals;
        FRAX_ERC20_PRECISION = 10 ** FRAX_ERC20_DECIMALS;
        USDC_ERC20_DECIMALS = _params.usdcErc20Decimals;
        USDC_ERC20_PRECISION = 10 ** USDC_ERC20_DECIMALS;
        FRAX_USDC_CURVE_POOL_LP_ERC20_DECIMALS = _params.fraxUsdcCurveLpErc20Decimals;
        FRAX_USDC_CURVE_POOL_LP_ERC20_PRECISION = 10 ** FRAX_USDC_CURVE_POOL_LP_ERC20_DECIMALS;

        USDC_TO_FRAX_NORMALIZATION = FRAX_ERC20_PRECISION / USDC_ERC20_PRECISION;
    }

    function name() external pure returns (string memory) {
        return "FraxUSDC Curve LP Dual Oracle w/ Min Max Bounds, Staleness Check";
    }

    // ====================================================================
    // Configuration Setters
    // ====================================================================

    /// @notice The ```setMinimumCurvePoolVirtualPrice``` function is used to set the minimum virtual price
    /// @param _newMinimum the new minimum virtual price
    function setMinimumCurvePoolVirtualPrice(uint256 _newMinimum) external override {
        _requireTimelock();
        _setMinimumCurvePoolVirtualPrice({ _newMinimum: _newMinimum });
    }

    /// @notice The ```setMaximumCurvePoolVirtualPrice``` function is used to set the maximum virtual price
    /// @param _newMaximum the new maximum virtual price
    function setMaximumCurvePoolVirtualPrice(uint256 _newMaximum) external override {
        _requireTimelock();
        _setMaximumCurvePoolVirtualPrice({ _newMaximum: _newMaximum });
    }

    function setMaximumOracleDelay(uint256 _newMaxOracleDelay) external override {
        _requireTimelock();
        _setMaximumOracleDelay({ _newMaxOracleDelay: _newMaxOracleDelay });
    }

    function setMaximumFraxUsdOracleDelay(uint256 _newMaxOracleDelay) external override {
        _requireTimelock();
        _setMaximumFraxUsdOracleDelay({ _newMaxOracleDelay: _newMaxOracleDelay });
    }

    function setFraxUsdcTwapDuration(uint32 _newTwapDuration) external override {
        _requireTimelock();
        _setFraxUsdcTwapDuration({ _newTwapDuration: _newTwapDuration });
    }

    // ====================================================================
    // Price Functions
    // ====================================================================

    /// @notice The ```getChainlinkUsdPerFrax``` function gets the Chainlink price of frax in usd units
    /// @dev normalized to match precision of oracle
    /// @return _isBadData Whether the Chainlink data is stale
    /// @return _usdPerFrax
    function getChainlinkUsdPerFrax() public view returns (bool _isBadData, uint256 _usdPerFrax) {
        (bool _isBadDataChainlink, , uint256 _usdPerFraxRaw) = _getFraxUsdChainlinkPrice();

        // Set return values
        _isBadData = _isBadDataChainlink;
        _usdPerFrax = (ORACLE_PRECISION * _usdPerFraxRaw) / CHAINLINK_FEED_PRECISION;
    }

    /// @notice The ```getFraxUsdcCurvePoolVirtualPrice``` function returns the normalized virtual price of the curve pool
    /// @return _virtualPrice The normalized virtual price of the curve pool
    function getFraxUsdcCurvePoolVirtualPrice() public view returns (uint256 _virtualPrice) {
        uint256 _virtualPriceRaw = _getCurvePoolVirtualPrice();

        // Set return values
        _virtualPrice = (_virtualPriceRaw * (ORACLE_PRECISION / CURVE_POOL_VIRTUAL_PRICE_PRECISION));
    }

    /// @notice The ```getChainlinkUsdPerUsdc``` function gets the Chainlink price of usdc in usd units
    /// @return _isBadData Whether the Chainlink data is stale or negative
    /// @return _usdPerUsdc The normalized price of usdc in usd units
    function getChainlinkUsdPerUsdc() public view returns (bool _isBadData, uint256 _usdPerUsdc) {
        (bool _isBadDataChainlink, , uint256 _usdPerUsdcRaw) = _getChainlinkPrice();

        // Set return values
        _isBadData = _isBadDataChainlink;
        _usdPerUsdc = (ORACLE_PRECISION * _usdPerUsdcRaw) / CHAINLINK_FEED_PRECISION;
    }

    /// @notice The ```getTwapFraxPerUsdc``` function gets the twap price of frax in usdc units
    /// @return _fraxPerUsdc The normalized price of frax in usdc units
    function getTwapFraxPerUsdc() public view returns (uint256 _fraxPerUsdc) {
        // _getFraxUsdcUniswapV3Twap() is configured to return UsdcPerFrax
        // Due to different decimals this number will be approximately 1e18 frax per 1e6 usdc and we want to return normalized values for comparisons
        _fraxPerUsdc =
            (ORACLE_PRECISION * _getFraxUsdcUniswapV3Twap()) /
            (FRAX_USDC_TWAP_PRECISION * USDC_TO_FRAX_NORMALIZATION);
    }

    /// @notice The ```getPricesNormalized``` function returns the normalized prices in human readable form
    /// @return _isBadDataNormal If the Chainlink oracle is stale
    /// @return _priceLowNormal The normalized low price
    /// @return _priceHighNormal The normalized high price
    function getPricesNormalized()
        external
        view
        returns (bool _isBadDataNormal, uint256 _priceLowNormal, uint256 _priceHighNormal)
    {
        (bool _isBadData, uint256 _priceLow, uint256 _priceHigh) = _getPrices();
        _isBadDataNormal = _isBadData;

        _priceLowNormal = NORMALIZATION_0 > 0
            ? _priceLow * 10 ** uint256(NORMALIZATION_0)
            : _priceLow / 10 ** (uint256(-NORMALIZATION_0));

        _priceHighNormal = NORMALIZATION_1 > 0
            ? _priceHigh * 10 ** uint256(NORMALIZATION_1)
            : _priceHigh / 10 ** (uint256(-NORMALIZATION_1));
    }

    /// @notice The ```calculatePrices``` function calculates the normalized prices in a pure function
    /// @param _isBadDataFraxUsdChainlink True if the FraxUsdChainlink returns stale data
    /// @param _usdPerFraxChainlink The price of frax in usd units
    /// @param _underlyingPerLp The amount of underlying per lp token from the curve pool
    /// @param _isBadDataUsdcUsdChainlink True if the UsdcUsdChainlink returns stale data
    /// @param _usdPerUsdcChainlink The price of usdc in usd units
    /// @param _fraxPerUsdcTwap The price of usdc in frax units
    /// @return _isBadData True if any of the oracles return stale data
    /// @return _priceLow The normalized low price
    /// @return _priceHigh The normalized high price
    function calculatePrices(
        bool _isBadDataFraxUsdChainlink,
        uint256 _usdPerFraxChainlink,
        uint256 _underlyingPerLp,
        bool _isBadDataUsdcUsdChainlink,
        uint256 _usdPerUsdcChainlink,
        uint256 _fraxPerUsdcTwap
    ) external pure returns (bool _isBadData, uint256 _priceLow, uint256 _priceHigh) {
        return
            _calculatePrices({
                _isBadDataFraxUsdChainlink: _isBadDataFraxUsdChainlink,
                _usdPerFraxChainlink: _usdPerFraxChainlink,
                _underlyingPerLp: _underlyingPerLp,
                _isBadDataUsdcUsdChainlink: _isBadDataUsdcUsdChainlink,
                _usdPerUsdcChainlink: _usdPerUsdcChainlink,
                _fraxPerUsdcTwap: _fraxPerUsdcTwap
            });
    }

    function _calculatePrices(
        bool _isBadDataFraxUsdChainlink,
        uint256 _usdPerFraxChainlink,
        uint256 _underlyingPerLp,
        bool _isBadDataUsdcUsdChainlink,
        uint256 _usdPerUsdcChainlink,
        uint256 _fraxPerUsdcTwap
    ) internal pure returns (bool _isBadData, uint256 _priceLow, uint256 _priceHigh) {
        // Usdc Chainlink Price in frax units
        uint256 _fraxPerUsdcChainlink = (ORACLE_PRECISION * _usdPerUsdcChainlink) / _usdPerFraxChainlink;

        // We know 1 FRAX = 1 FRAX so we check if the values are less than 1
        // We want to return the value which represents the least valuable collateral
        uint256 _fraxPerUnderlying1 = _fraxPerUsdcTwap < ORACLE_PRECISION ? _fraxPerUsdcTwap : ORACLE_PRECISION;
        uint256 _fraxPerUnderlying2 = _fraxPerUsdcChainlink < ORACLE_PRECISION
            ? _fraxPerUsdcChainlink
            : ORACLE_PRECISION;

        // Multiply by virtualPrice
        uint256 _fraxPerLp1 = (_fraxPerUnderlying1 * _underlyingPerLp) / ORACLE_PRECISION;
        uint256 _fraxPerLp2 = (_fraxPerUnderlying2 * _underlyingPerLp) / ORACLE_PRECISION;

        // Flip values so that they are in the form of collateral/asset
        uint256 _lpPerFrax1 = (ORACLE_PRECISION * ORACLE_PRECISION) / _fraxPerLp1;
        uint256 _lpPerFrax2 = (ORACLE_PRECISION * ORACLE_PRECISION) / _fraxPerLp2;

        // Set return values
        _isBadData = _isBadDataUsdcUsdChainlink || _isBadDataFraxUsdChainlink;
        _priceLow = _lpPerFrax1 < _lpPerFrax2 ? _lpPerFrax1 : _lpPerFrax2;
        _priceHigh = _lpPerFrax1 > _lpPerFrax2 ? _lpPerFrax1 : _lpPerFrax2;
    }

    function _getPrices() internal view returns (bool _isBadData, uint256 _priceLow, uint256 _priceHigh) {
        // These values have been normalized to ORACLE_PRECISION
        (bool _isBadDataFraxUsdChainlink, uint256 _usdPerFraxChainlink) = getChainlinkUsdPerFrax();
        uint256 _underlyingPerLp = getFraxUsdcCurvePoolVirtualPrice();
        (bool _isBadDataUsdcUsdChainlink, uint256 _usdPerUsdcChainlink) = getChainlinkUsdPerUsdc();
        uint256 _fraxPerUsdcTwap = getTwapFraxPerUsdc();

        // Set return values
        (_isBadData, _priceLow, _priceHigh) = _calculatePrices({
            _isBadDataFraxUsdChainlink: _isBadDataFraxUsdChainlink,
            _usdPerFraxChainlink: _usdPerFraxChainlink,
            _underlyingPerLp: _underlyingPerLp,
            _isBadDataUsdcUsdChainlink: _isBadDataUsdcUsdChainlink,
            _usdPerUsdcChainlink: _usdPerUsdcChainlink,
            _fraxPerUsdcTwap: _fraxPerUsdcTwap
        });
    }

    /// @notice The ```getPrices``` function is intended to return two prices from different oracles
    /// @return _isBadData is true when data is stale or otherwise bad
    /// @return _priceLow is the lower of the two prices
    /// @return _priceHigh is the higher of the two prices
    function getPrices() external view returns (bool _isBadData, uint256 _priceLow, uint256 _priceHigh) {
        return _getPrices();
    }
}