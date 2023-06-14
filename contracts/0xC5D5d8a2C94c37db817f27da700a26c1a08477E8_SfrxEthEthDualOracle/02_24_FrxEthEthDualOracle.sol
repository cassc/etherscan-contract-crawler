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
// ========================== FraxDualOracle ==========================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Author
// Jon Walch: https://github.com/jonwalch

// Reviewers
// Drake Evans: https://github.com/DrakeEvans
// Dennis: https://github.com/denett

// ====================================================================
import { ERC165Storage } from "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import { Timelock2Step } from "frax-std/access-control/v1/Timelock2Step.sol";
import { ITimelock2Step } from "frax-std/access-control/v1/interfaces/ITimelock2Step.sol";
import { DualOracleBase, ConstructorParams as DualOracleBaseParams } from "src/DualOracleBase.sol";
import {
    UniswapV3SingleTwapOracle,
    ConstructorParams as UniswapV3SingleTwapOracleParams
} from "./abstracts/UniswapV3SingleTwapOracle.sol";
import {
    EthUsdChainlinkOracleWithMaxDelay,
    ConstructorParams as EthUsdChainlinkOracleWithMaxDelayParams
} from "./abstracts/EthUsdChainlinkOracleWithMaxDelay.sol";
import {
    CurvePoolEmaPriceOracleWithMinMax,
    ConstructorParams as CurvePoolEmaPriceOracleWithMinMaxParams
} from "./abstracts/CurvePoolEmaPriceOracleWithMinMax.sol";
import {
    FraxUsdChainlinkOracleWithMaxDelay,
    ConstructorParams as FraxUsdChainlinkOracleWithMaxDelayParams
} from "./abstracts/FraxUsdChainlinkOracleWithMaxDelay.sol";
import { IDualOracle } from "interfaces/IDualOracle.sol";
import { IPriceSource } from "./interfaces/IPriceSource.sol";
import { IPriceSourceReceiver } from "./interfaces/IPriceSourceReceiver.sol";

struct ConstructorParams {
    // = DualOracleBase
    address baseToken0; // frxEth
    uint8 baseToken0Decimals;
    address quoteToken0; // weth
    uint8 quoteToken0Decimals;
    address baseToken1; // frxEth
    uint8 baseToken1Decimals;
    address quoteToken1; // weth
    uint8 quoteToken1Decimals;
    // = UniswapV3SingleTwapOracle
    address frxEthErc20;
    address fraxErc20;
    address uniV3PairAddress;
    uint32 twapDuration;
    // = FraxUsdChainlinkOracleWithMaxDelay
    address fraxUsdChainlinkFeedAddress;
    uint256 fraxUsdMaximumOracleDelay;
    // = EthUsdChainlinkOracleWithMaxDelay
    address ethUsdChainlinkFeed;
    uint256 maxEthUsdOracleDelay;
    // = CurvePoolEmaPriceOracleWithMinMax
    address curvePoolEmaPriceOracleAddress;
    uint256 minimumCurvePoolEma;
    uint256 maximumCurvePoolEma;
    // = Timelock2Step
    address timelockAddress;
}

/// @title FrxEthEthDualOracle
/// @author Jon Walch (Frax Finance) https://github.com/jonwalch
/// @notice This oracle feeds prices to our new FraxOracle system, not intended to be used with Fraxlend
/// @dev Returns prices of Frax assets in Ether
contract FrxEthEthDualOracle is
    DualOracleBase,
    CurvePoolEmaPriceOracleWithMinMax,
    UniswapV3SingleTwapOracle,
    FraxUsdChainlinkOracleWithMaxDelay,
    EthUsdChainlinkOracleWithMaxDelay,
    IPriceSource,
    Timelock2Step
{
    /// @notice The address of the Erc20 token contract
    address public immutable FRXETH_ERC20;

    constructor(
        ConstructorParams memory params
    )
        DualOracleBase(
            DualOracleBaseParams({
                baseToken0: params.baseToken0,
                baseToken0Decimals: params.baseToken0Decimals,
                quoteToken0: params.quoteToken0,
                quoteToken0Decimals: params.quoteToken0Decimals,
                baseToken1: params.baseToken1,
                baseToken1Decimals: params.baseToken1Decimals,
                quoteToken1: params.quoteToken1,
                quoteToken1Decimals: params.quoteToken1Decimals
            })
        )
        CurvePoolEmaPriceOracleWithMinMax(
            CurvePoolEmaPriceOracleWithMinMaxParams({
                curvePoolEmaPriceOracleAddress: params.curvePoolEmaPriceOracleAddress,
                minimumCurvePoolEma: params.minimumCurvePoolEma,
                maximumCurvePoolEma: params.maximumCurvePoolEma
            })
        )
        UniswapV3SingleTwapOracle(
            UniswapV3SingleTwapOracleParams({
                uniswapV3PairAddress: params.uniV3PairAddress,
                twapDuration: params.twapDuration,
                baseToken: params.frxEthErc20,
                quoteToken: params.fraxErc20
            })
        )
        EthUsdChainlinkOracleWithMaxDelay(
            EthUsdChainlinkOracleWithMaxDelayParams({
                ethUsdChainlinkFeedAddress: params.ethUsdChainlinkFeed,
                maxEthUsdOracleDelay: params.maxEthUsdOracleDelay
            })
        )
        FraxUsdChainlinkOracleWithMaxDelay(
            FraxUsdChainlinkOracleWithMaxDelayParams({
                fraxUsdChainlinkFeedAddress: params.fraxUsdChainlinkFeedAddress,
                fraxUsdMaximumOracleDelay: params.fraxUsdMaximumOracleDelay
            })
        )
        Timelock2Step()
    {
        _setTimelock({ _newTimelock: params.timelockAddress });
        _registerInterface({ interfaceId: type(IDualOracle).interfaceId });
        _registerInterface({ interfaceId: type(ITimelock2Step).interfaceId });
        _registerInterface({ interfaceId: type(IPriceSource).interfaceId });

        FRXETH_ERC20 = params.frxEthErc20;
    }

    // ====================================================================
    // View Helpers
    // ====================================================================

    /// @notice The ```name``` function returns the name of the contract
    /// @return _name The name of the contract
    function name() external view virtual returns (string memory _name) {
        _name = "frxEth Dual Oracle In Eth with Curve Pool EMA and Uniswap v3 TWAP and Frax and ETH Chainlink";
    }

    // ====================================================================
    // Configuration Setters
    // ====================================================================

    /// @notice The ```setMinimumCurvePoolEma``` function sets the minimum price of frxEth in Ether units of the EMA
    /// @dev Must match precision of the EMA
    /// @param minimumPrice The minimum price of frxEth in Ether units of the EMA
    function setMinimumCurvePoolEma(uint256 minimumPrice) external override {
        _requireTimelock();
        _setMinimumCurvePoolEma({ _minimumPrice: minimumPrice });
    }

    /// @notice The ```setMaximumCurvePoolEma``` function sets the maximum price of frxEth in Ether units of the EMA
    /// @dev Must match precision of the EMA
    /// @param maximumPrice The maximum price of frxEth in Ether units of the EMA
    function setMaximumCurvePoolEma(uint256 maximumPrice) external override {
        _requireTimelock();
        _setMaximumCurvePoolEma({ _maximumPrice: maximumPrice });
    }

    /// @notice The ```setTwapDuration``` function sets the TWAP duration for the Uniswap V3 oracle
    /// @dev Must be called by the timelock
    /// @param newTwapDuration The new TWAP duration
    function setTwapDuration(uint32 newTwapDuration) external override {
        _requireTimelock();
        _setTwapDuration({ _newTwapDuration: newTwapDuration });
    }

    /// @notice The ```setMaximumOracleDelay``` function sets the max oracle delay to determine if Chainlink data is stale
    /// @dev Requires msg.sender to be the timelock address
    /// @param newMaxOracleDelay The new max oracle delay
    function setMaximumEthUsdOracleDelay(uint256 newMaxOracleDelay) external override {
        _requireTimelock();
        _setMaximumEthUsdOracleDelay({ _newMaxOracleDelay: newMaxOracleDelay });
    }

    /// @notice The ```setMaximumFraxUsdOracleDelay``` function sets the max oracle delay to determine if Chainlink data is stale
    /// @dev Must be called by the timelock
    /// @param newMaxOracleDelay The new max oracle delay
    function setMaximumFraxUsdOracleDelay(uint256 newMaxOracleDelay) external override {
        _requireTimelock();
        _setMaximumFraxUsdOracleDelay({ _newMaxOracleDelay: newMaxOracleDelay });
    }

    // ====================================================================
    // Price Source Function
    // ====================================================================

    /// @notice The ```addRoundData``` adds new price data to a FraxOracle
    /// @param fraxOracle Address of a FraxOracle that has this contract set as its priceSource
    function addRoundData(IPriceSourceReceiver fraxOracle) external {
        (bool isBadData, uint256 priceLow, uint256 priceHigh) = _getPrices();
        // Authorization is handled on fraxOracle side
        fraxOracle.addRoundData({
            isBadData: isBadData,
            priceLow: uint104(priceLow),
            priceHigh: uint104(priceHigh),
            timestamp: uint40(block.timestamp)
        });
    }

    // ====================================================================
    // Price Functions
    // ====================================================================

    /// @notice The ```getCurveEmaEthPerFrxEth``` function gets the EMA price of frxEth in eth units
    /// @dev normalized to match precision of oracle
    /// @return ethPerFrxEth
    function getCurveEmaEthPerFrxEth() public view returns (uint256 ethPerFrxEth) {
        ethPerFrxEth = _getCurvePoolToken1EmaPrice();

        // Note: ORACLE_PRECISION == CURVE_POOL_EMA_PRICE_ORACLE_PRECISION
        // _ethPerFrxEth = (ORACLE_PRECISION * _getCurvePoolToken1EmaPrice()) / CURVE_POOL_EMA_PRICE_ORACLE_PRECISION;
    }

    /// @notice The ```getChainlinkUsdPerFrax``` function gets the Chainlink price of frax in usd units
    /// @dev normalized to match precision of oracle
    /// @return isBadData Whether the Chainlink data is stale
    /// @return usdPerFrax
    function getChainlinkUsdPerFrax() public view returns (bool isBadData, uint256 usdPerFrax) {
        (bool isBadDataChainlink, , uint256 usdPerFraxRaw) = _getFraxUsdChainlinkPrice();

        // Set return values
        isBadData = isBadDataChainlink;
        usdPerFrax = (ORACLE_PRECISION * usdPerFraxRaw) / FRAX_USD_CHAINLINK_FEED_PRECISION;
    }

    /// @notice The ```getUsdPerEthChainlink``` function returns USD per ETH using the Chainlink oracle
    /// @return isBadData If the Chainlink oracle is stale
    /// @return usdPerEth The Eth Price is usd units
    function getUsdPerEthChainlink() public view returns (bool isBadData, uint256 usdPerEth) {
        uint256 usdPerEthChainlinkRaw;
        (isBadData, , usdPerEthChainlinkRaw) = _getEthUsdChainlinkPrice();
        usdPerEth = (ORACLE_PRECISION * usdPerEthChainlinkRaw) / ETH_USD_CHAINLINK_FEED_PRECISION;
    }

    function _calculatePrices(
        uint256 ethPerFrxEthCurveEma,
        uint256 fraxPerFrxEthTwap,
        bool isBadDataEthUsdChainlink,
        uint256 usdPerEthChainlink,
        bool isBadDataFraxUsdChainlink,
        uint256 usdPerFraxChainlink
    ) internal view virtual returns (bool isBadData, uint256 priceLow, uint256 priceHigh) {
        uint256 ethPerFrxEthRawTwap = (fraxPerFrxEthTwap * usdPerFraxChainlink) / usdPerEthChainlink;

        uint256 _maximumCurvePoolEma = maximumCurvePoolEma;
        uint256 _minimumCurvePoolEma = minimumCurvePoolEma;

        // Bound uniswap twap + chainlink price to same price min/max constraints as the curvePoolEma
        uint256 twapEthPerFrxEthHighBounded = ethPerFrxEthRawTwap > _maximumCurvePoolEma
            ? _maximumCurvePoolEma
            : ethPerFrxEthRawTwap;

        uint256 twapEthPerFrxEth = twapEthPerFrxEthHighBounded < _minimumCurvePoolEma
            ? _minimumCurvePoolEma
            : twapEthPerFrxEthHighBounded;

        isBadData = isBadDataEthUsdChainlink || isBadDataFraxUsdChainlink;
        priceLow = ethPerFrxEthCurveEma < twapEthPerFrxEth ? ethPerFrxEthCurveEma : twapEthPerFrxEth;
        priceHigh = twapEthPerFrxEth > ethPerFrxEthCurveEma ? twapEthPerFrxEth : ethPerFrxEthCurveEma;
    }

    /// @notice The ```calculatePrices``` function calculates the normalized prices in a pure function
    /// @return isBadData True if any of the oracles return stale data
    /// @return priceLow The normalized low price
    /// @return priceHigh The normalized high price
    function calculatePrices(
        uint256 ethPerFrxEthCurveEma,
        uint256 fraxPerFrxEthTwap,
        bool isBadDataEthUsdChainlink,
        uint256 usdPerEthChainlink,
        bool isBadDataFraxUsdChainlink,
        uint256 usdPerFraxChainlink
    ) external view returns (bool isBadData, uint256 priceLow, uint256 priceHigh) {
        (isBadData, priceLow, priceHigh) = _calculatePrices({
            ethPerFrxEthCurveEma: ethPerFrxEthCurveEma,
            fraxPerFrxEthTwap: fraxPerFrxEthTwap,
            isBadDataEthUsdChainlink: isBadDataEthUsdChainlink,
            usdPerEthChainlink: usdPerEthChainlink,
            isBadDataFraxUsdChainlink: isBadDataFraxUsdChainlink,
            usdPerFraxChainlink: usdPerFraxChainlink
        });
    }

    function _getPrices() internal view returns (bool isBadData, uint256 priceLow, uint256 priceHigh) {
        // first price
        uint256 ethPerFrxEthCurveEma = getCurveEmaEthPerFrxEth();

        // second price
        uint256 fraxPerFrxEthTwap = _getUniswapV3Twap();
        (bool isBadDataEthUsdChainlink, uint256 usdPerEthChainlink) = getUsdPerEthChainlink();
        (bool isBadDataFraxUsdChainlink, uint256 usdPerFraxChainlink) = getChainlinkUsdPerFrax();

        (isBadData, priceLow, priceHigh) = _calculatePrices({
            ethPerFrxEthCurveEma: ethPerFrxEthCurveEma,
            fraxPerFrxEthTwap: fraxPerFrxEthTwap,
            isBadDataEthUsdChainlink: isBadDataEthUsdChainlink,
            usdPerEthChainlink: usdPerEthChainlink,
            isBadDataFraxUsdChainlink: isBadDataFraxUsdChainlink,
            usdPerFraxChainlink: usdPerFraxChainlink
        });
    }

    /// @notice The ```getPrices``` function is intended to return two prices from different oracles
    /// @return isBadData is true when data is stale or otherwise bad
    /// @return priceLow is the lower of the two prices
    /// @return priceHigh is the higher of the two prices
    function getPrices() external view returns (bool isBadData, uint256 priceLow, uint256 priceHigh) {
        (isBadData, priceLow, priceHigh) = _getPrices();
    }

    /// @notice The ```getPricesNormalized``` function returns the normalized prices in human readable form
    /// @dev decimals of underlying tokens match so we can just return _getPrices()
    /// @return isBadDataNormal If the oracle is stale
    /// @return priceLowNormal The normalized low price
    /// @return priceHighNormal The normalized high price
    function getPricesNormalized()
        external
        view
        override
        returns (bool isBadDataNormal, uint256 priceLowNormal, uint256 priceHighNormal)
    {
        (isBadDataNormal, priceLowNormal, priceHighNormal) = _getPrices();
    }
}