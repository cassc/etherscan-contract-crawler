// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { PriceFeedType } from "@gearbox-protocol/core-v2/contracts/interfaces/IPriceFeedType.sol";
import { LPPriceFeed } from "@gearbox-protocol/core-v2/contracts/oracles/LPPriceFeed.sol";

import { IwstETH } from "../../integrations/lido/IwstETH.sol";
// EXCEPTIONS
import { ZeroAddressException, NotImplementedException } from "@gearbox-protocol/core-v2/contracts/interfaces/IErrors.sol";

uint256 constant RANGE_WIDTH = 200; // 2%

/// @title Yearn price feed
contract WstETHPriceFeed is LPPriceFeed {
    /// @dev Chainlink price feed for the stETH token
    AggregatorV3Interface public immutable priceFeed;

    /// @dev wstETH token address
    IwstETH public immutable wstETH;

    /// @dev Format of the wstETH's stETHperToken()
    uint256 public immutable decimalsDivider;

    PriceFeedType public constant override priceFeedType =
        PriceFeedType.WSTETH_ORACLE;

    uint256 public constant override version = 1;

    /// @dev Whether to skip price sanity checks.
    /// @notice Always set to true for LP price feeds,
    ///         since they perform their own sanity checks
    bool public constant override skipPriceCheck = true;

    constructor(
        address addressProvider,
        address _wstETH,
        address _priceFeed
    )
        LPPriceFeed(
            addressProvider,
            RANGE_WIDTH,
            _wstETH != address(0)
                ? string(
                    abi.encodePacked(
                        IERC20Metadata(_wstETH).name(),
                        " priceFeed"
                    )
                )
                : ""
        ) // F:[WSTPF-1]
    {
        if (_wstETH == address(0) || _priceFeed == address(0))
            revert ZeroAddressException(); // F:[WSTPF-2]

        wstETH = IwstETH(_wstETH); // F:[WSTPF-1]
        priceFeed = AggregatorV3Interface(_priceFeed); // F:[WSTPF-1]

        decimalsDivider = 10**IwstETH(_wstETH).decimals(); // F:[WSTPF-1]
        uint256 stEthPerToken = IwstETH(_wstETH).stEthPerToken(); // F:[WSTPF-1]
        _setLimiter(stEthPerToken); // F:[WSTPF-1]
    }

    /// @dev Returns the USD price of the pool's LP token
    /// @notice Computes the vault share price as (price(underlying) * pricePerShare())
    ///         See more at https://dev.gearbox.fi/docs/documentation/oracle/yearn-pricefeed
    function latestRoundData()
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        (roundId, answer, startedAt, updatedAt, answeredInRound) = priceFeed
            .latestRoundData(); // F:[WSTPF-4]

        // Sanity check for chainlink pricefeed
        _checkAnswer(roundId, answer, updatedAt, answeredInRound); // F:[WSTPF-5]

        uint256 stEthPerToken = wstETH.stEthPerToken(); // F:[WSTPF-4]

        // Checks that pricePerShare is within bounds
        stEthPerToken = _checkAndUpperBoundValue(stEthPerToken); // F:[WSTPF-5]

        answer = int256((stEthPerToken * uint256(answer)) / decimalsDivider); // F:[WSTPF-4]
    }

    function _checkCurrentValueInBounds(uint256 _lowerBound, uint256 _uBound)
        internal
        view
        override
        returns (bool)
    {
        uint256 pps = wstETH.stEthPerToken();
        if (pps < _lowerBound || pps > _uBound) {
            return false;
        }
        return true;
    }
}