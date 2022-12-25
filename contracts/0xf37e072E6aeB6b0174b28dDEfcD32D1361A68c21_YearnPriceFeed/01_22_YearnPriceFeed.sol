// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { PriceFeedType } from "@gearbox-protocol/core-v2/contracts/interfaces/IPriceFeedType.sol";
import { LPPriceFeed } from "@gearbox-protocol/core-v2/contracts/oracles/LPPriceFeed.sol";

import { IYVault } from "../../integrations/yearn/IYVault.sol";

// EXCEPTIONS
import { ZeroAddressException, NotImplementedException } from "@gearbox-protocol/core-v2/contracts/interfaces/IErrors.sol";

uint256 constant RANGE_WIDTH = 200; // 2%

/// @title Yearn price feed
contract YearnPriceFeed is LPPriceFeed {
    /// @dev Chainlink price feed for the Vault's underlying
    AggregatorV3Interface public immutable priceFeed;

    /// @dev Address of the vault to compute prices for
    IYVault public immutable yVault;

    /// @dev Format of the vault's pricePerShare()
    uint256 public immutable decimalsDivider;

    PriceFeedType public constant override priceFeedType =
        PriceFeedType.YEARN_ORACLE;
    uint256 public constant override version = 2;

    /// @dev Whether to skip price sanity checks.
    /// @notice Always set to true for LP price feeds,
    ///         since they perform their own sanity checks
    bool public constant override skipPriceCheck = true;

    constructor(
        address addressProvider,
        address _yVault,
        address _priceFeed
    )
        LPPriceFeed(
            addressProvider,
            RANGE_WIDTH, // F:[YPF-1]
            _yVault != address(0)
                ? string(
                    abi.encodePacked(
                        IERC20Metadata(_yVault).name(),
                        " priceFeed"
                    ) // F:[YPF-1]
                )
                : ""
        )
    {
        if (_yVault == address(0) || _priceFeed == address(0))
            revert ZeroAddressException(); // F:[OYPF-2]

        yVault = IYVault(_yVault); // F:[OYPF-1]
        priceFeed = AggregatorV3Interface(_priceFeed); // F:[OYPF-1]

        decimalsDivider = 10**IYVault(_yVault).decimals(); // F:[OYPF-1]
        uint256 pricePerShare = IYVault(_yVault).pricePerShare(); // F:[OYPF-1]
        _setLimiter(pricePerShare); // F:[OYPF-1]
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
            .latestRoundData(); // F:[OYPF-4]

        // Sanity check for chainlink pricefeed
        _checkAnswer(roundId, answer, updatedAt, answeredInRound); // F:[OYPF-5]

        uint256 pricePerShare = yVault.pricePerShare(); // F:[OYPF-4]

        // Checks that pricePerShare is within bounds
        pricePerShare = _checkAndUpperBoundValue(pricePerShare); // F:[OYPF-5]

        answer = int256((pricePerShare * uint256(answer)) / decimalsDivider); // F:[OYPF-4]
    }

    function _checkCurrentValueInBounds(uint256 _lowerBound, uint256 _uBound)
        internal
        view
        override
        returns (bool)
    {
        uint256 pps = yVault.pricePerShare();
        if (pps < _lowerBound || pps > _uBound) {
            return false;
        }
        return true;
    }
}