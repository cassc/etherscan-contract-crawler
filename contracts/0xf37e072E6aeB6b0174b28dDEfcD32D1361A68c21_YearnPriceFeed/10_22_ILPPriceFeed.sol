// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { IPriceFeedType } from "./IPriceFeedType.sol";

interface ILPPriceFeedEvents {
    /// @dev Emits on updating the virtual price bounds
    event NewLimiterParams(uint256 lowerBound, uint256 upperBound);
}

interface ILPPriceFeedExceptions {
    /// @dev Thrown on returning a value that violates the current bounds
    error ValueOutOfRangeException();

    /// @dev Thrown on failing sanity checks when setting new bounds
    error IncorrectLimitsException();
}

/// @title Interface for LP PriceFeeds with limiter
interface ILPPriceFeed is
    AggregatorV3Interface,
    IPriceFeedType,
    ILPPriceFeedEvents,
    ILPPriceFeedExceptions
{
    /// @dev Sets the lower and upper bounds for virtual price.
    /// @param _lowerBound The new lower bound
    /// @notice The upper bound is computed automatically
    function setLimiter(uint256 _lowerBound) external;

    /// @dev Returns the lower bound
    function lowerBound() external view returns (uint256);

    /// @dev Returns the upper bound
    function upperBound() external view returns (uint256);

    /// @dev Returns the pre-defined window between the lower and upper bounds
    /// @notice In bp format
    function delta() external view returns (uint256);
}