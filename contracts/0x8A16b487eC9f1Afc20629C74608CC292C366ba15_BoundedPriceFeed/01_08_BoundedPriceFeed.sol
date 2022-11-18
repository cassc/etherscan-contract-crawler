// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { AggregatorV2V3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";
import { PERCENTAGE_FACTOR } from "../libraries/PercentageMath.sol";
import { PriceFeedType, IPriceFeedType } from "../interfaces/IPriceFeedType.sol";

// EXCEPTIONS
import { NotImplementedException } from "../interfaces/IErrors.sol";

interface ChainlinkReadableAggregator {
    function aggregator() external view returns (address);

    function phaseAggregators(uint16 idx)
        external
        view
        returns (AggregatorV2V3Interface);

    function phaseId() external view returns (uint16);
}

/// @title Price feed with an upper bound on price
/// @notice Used to limit prices on assets that should not rise above
///         a certain level, such as stablecoins and other pegged assets
contract BoundedPriceFeed is
    ChainlinkReadableAggregator,
    AggregatorV3Interface,
    IPriceFeedType
{
    /// @dev Chainlink price feed for the Vault's underlying
    AggregatorV3Interface public immutable priceFeed;

    /// @dev The upper bound on Chainlink price for the asset
    int256 public immutable upperBound;

    /// @dev Decimals of the returned result.
    uint8 public immutable override decimals;

    /// @dev Price feed description
    string public override description;

    uint256 public constant override version = 1;

    PriceFeedType public constant override priceFeedType =
        PriceFeedType.BOUNDED_ORACLE;

    bool public constant override skipPriceCheck = false;

    /// @dev Constructor
    /// @param _priceFeed Chainlink price feed to receive results from
    /// @param _upperBound Initial upper bound for the Chainlink price
    constructor(address _priceFeed, int256 _upperBound) {
        priceFeed = AggregatorV3Interface(_priceFeed);
        description = string(
            abi.encodePacked(priceFeed.description(), " Bounded")
        );
        decimals = priceFeed.decimals();
        upperBound = _upperBound;
    }

    /// @dev Implemented for compatibility, but reverts since Gearbox's price feeds
    ///      do not store historical data.
    function getRoundData(uint80)
        external
        pure
        virtual
        override
        returns (
            uint80, // roundId,
            int256, // answer,
            uint256, // startedAt,
            uint256, // updatedAt,
            uint80 // answeredInRound
        )
    {
        revert NotImplementedException(); // F:[LPF-2]
    }

    /// @dev Returns the value if it is below the upper bound, otherwise returns the upper bound
    /// @param value Value to be checked and bounded
    function _upperBoundValue(int256 value) internal view returns (int256) {
        return (value > upperBound) ? upperBound : value;
    }

    /// @dev Returns the upper-bounded USD price of the token
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

        answer = _upperBoundValue(answer);
    }

    /// @dev Returns the current phase's aggregator address
    function aggregator() external view returns (address) {
        return ChainlinkReadableAggregator(address(priceFeed)).aggregator();
    }

    /// @dev Returns a phase aggregator by index
    function phaseAggregators(uint16 idx)
        external
        view
        returns (AggregatorV2V3Interface)
    {
        return
            ChainlinkReadableAggregator(address(priceFeed)).phaseAggregators(
                idx
            );
    }

    function phaseId() external view returns (uint16) {
        return ChainlinkReadableAggregator(address(priceFeed)).phaseId();
    }
}