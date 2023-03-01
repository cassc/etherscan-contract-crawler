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
// ======================== ApeCoinDualOracle =========================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Author
// Drake Evans: https://github.com/DrakeEvans

// Reviewers
// Dennis: https://github.com/denett

// ====================================================================

import { Timelock2Step } from "../../Timelock2Step.sol";
import { UniswapV3SingleTwapOracle, ConstructorParams as UniswapV3SingleTwapOracleParams } from "./abstracts/UniswapV3SingleTwapOracle.sol";
import { ChainlinkOracleWithMaxDelay, ConstructorParams as ChainlinkOracleWithMaxDelayParams } from "./abstracts/ChainlinkOracleWithMaxDelay.sol";
import { EthUsdChainlinkOracleWithMaxDelay, ConstructorParams as EthUsdChainlinkOracleWithMaxDelayParams } from "./abstracts/EthUsdChainlinkOracleWithMaxDelay.sol";
import "../../interfaces/IDualOracle.sol";
import "../../interfaces/IStableSwap.sol";
import "../../interfaces/ITimelock2Step.sol";

/// @title ApeCoinDualOracle
/// @author Drake Evans (Frax Finance) https://github.com/drakeevans
/// @notice  An oracle for ApeCoin in Frax units
contract ApeCoinDualOracle is
    Timelock2Step,
    UniswapV3SingleTwapOracle,
    ChainlinkOracleWithMaxDelay,
    EthUsdChainlinkOracleWithMaxDelay
{
    uint256 public constant ORACLE_PRECISION = 1e18;
    address public immutable FRAX_ERC20;
    address public immutable APE_ERC20;

    /// @notice The oracle type, used for internal monitoring
    /// @dev breaks ALL_CAPS convention to adhere to interface
    uint256 public constant oracleType = 0;

    constructor(
        address _fraxErc20,
        address _apeErc20,
        address _wethErc20,
        address _apeUsdChainlinkFeed,
        uint256 _maximumOracleDelay,
        address _ethUsdChainlinkFeed,
        uint256 _maxEthUsdOracleDelay,
        address _uniV3PairAddress,
        uint32 _twapDuration,
        address _timelockAddress
    )
        Timelock2Step()
        UniswapV3SingleTwapOracle(
            UniswapV3SingleTwapOracleParams({
                uniswapV3PairAddress: _uniV3PairAddress,
                twapDuration: _twapDuration,
                baseToken: _wethErc20,
                quoteToken: _apeErc20
            })
        )
        ChainlinkOracleWithMaxDelay(
            ChainlinkOracleWithMaxDelayParams({
                chainlinkFeedAddress: _apeUsdChainlinkFeed,
                maximumOracleDelay: _maximumOracleDelay
            })
        )
        EthUsdChainlinkOracleWithMaxDelay(
            EthUsdChainlinkOracleWithMaxDelayParams({
                ethUsdChainlinkFeedAddress: _ethUsdChainlinkFeed,
                maxEthUsdOracleDelay: _maxEthUsdOracleDelay
            })
        )
    {
        _setTimelock({ _newTimelock: _timelockAddress });
        _registerInterface({ interfaceId: type(IDualOracle).interfaceId });
        _registerInterface({ interfaceId: type(ITimelock2Step).interfaceId });

        FRAX_ERC20 = _fraxErc20;
        APE_ERC20 = _apeErc20;
    }

    // ====================================================================
    // View Helpers
    // ====================================================================

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function name() external pure returns (string memory) {
        return "Ape Coin Dual Oracle Chainlink with Staleness Check and Uniswap V3 TWAP";
    }

    function quoteToken() external view returns (address) {
        return APE_ERC20;
    }

    function baseToken() external view returns (address) {
        return FRAX_ERC20;
    }

    // ====================================================================
    // Configuration Setters
    // ====================================================================

    /// @notice The ```setMaximumOracleDelay``` function sets the max oracle delay to determine if Chainlink data is stale
    /// @dev Requires msg.sender to be the timelock address
    /// @param _newMaxOracleDelay The new max oracle delay
    function setMaximumOracleDelay(uint256 _newMaxOracleDelay) external override {
        _requireTimelock();
        _setMaximumOracleDelay({ _newMaxOracleDelay: _newMaxOracleDelay });
    }

    function setMaximumEthUsdOracleDelay(uint256 _newMaxOracleDelay) external override {
        _requireTimelock();
        _setMaximumEthUsdOracleDelay({ _newMaxOracleDelay: _newMaxOracleDelay });
    }

    /// @notice The ```setTwapDuration``` function sets the twap duration for the Uniswap V3 TWAP oracle
    /// @dev Requires msg.sender to be the timelock address
    /// @param _newTwapDuration The new twap duration
    function setTwapDuration(uint32 _newTwapDuration) external override {
        _requireTimelock();
        _setTwapDuration({ _newTwapDuration: _newTwapDuration });
    }

    // ====================================================================
    // Price Functions
    // ====================================================================

    function getApePerUsdTwap() public view returns (bool _isBadData, uint256 _apePerUsd) {
        uint256 _apePerWeth = _getUniswapV3Twap();
        uint256 _usdPerEth;
        (_isBadData, , _usdPerEth) = _getEthUsdChainlinkPrice();
        _apePerUsd = (_apePerWeth * ETH_USD_CHAINLINK_FEED_PRECISION) / _usdPerEth;
    }

    function getApePerUsdChainlink() public view returns (bool _isBadData, uint256 _apePerUsd) {
        (bool _isBadDataChainlink, , uint256 _usdPerApeChainlinkRaw) = _getChainlinkPrice();
        _apePerUsd = (ORACLE_PRECISION * CHAINLINK_FEED_PRECISION) / _usdPerApeChainlinkRaw;
    }

    /// @notice The ```getPrices``` function is intended to return two prices from different oracles
    /// @return _isBadData is true when data is stale or otherwise bad
    /// @return _priceLow is the lower of the two prices
    /// @return _priceHigh is the higher of the two prices
    function getPrices() external view returns (bool _isBadData, uint256 _priceLow, uint256 _priceHigh) {
        (bool _isBadDataChainlink, uint256 _apePerUsdChainlink) = getApePerUsdChainlink();

        (bool _isBadDataTwap, uint256 _apePerUsdTwap) = getApePerUsdTwap();
        if (_isBadDataChainlink && _isBadDataTwap) {
            revert("Both Chainlink and TWAP are bad");
        }
        if (_isBadDataChainlink) {
            _priceLow = _apePerUsdTwap;
            _priceHigh = _apePerUsdTwap;
        } else if (_isBadDataTwap) {
            _priceLow = _apePerUsdChainlink;
            _priceHigh = _apePerUsdChainlink;
        } else if (_apePerUsdChainlink < _apePerUsdTwap) {
            _priceLow = _apePerUsdChainlink;
            _priceHigh = _apePerUsdTwap;
        } else {
            _priceLow = _apePerUsdTwap;
            _priceHigh = _apePerUsdChainlink;
        }
    }
}