// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

import { ILPPriceFeed } from "../interfaces/ILPPriceFeed.sol";
import { PriceFeedChecker } from "./PriceFeedChecker.sol";
import { ACLTrait } from "../core/ACLTrait.sol";
import { PERCENTAGE_FACTOR } from "../libraries/PercentageMath.sol";

// EXCEPTIONS
import { NotImplementedException } from "../interfaces/IErrors.sol";

/// @title Abstract PriceFeed for an LP token
/// @notice For most pools/vaults, the LP token price depends on Chainlink prices of pool assets and the pool's
/// internal exchange rate.
abstract contract LPPriceFeed is ILPPriceFeed, PriceFeedChecker, ACLTrait {
    /// @dev The lower bound for the contract's token-to-underlying exchange rate.
    /// @notice Used to protect against LP token / share price manipulation.
    uint256 public lowerBound;

    /// @dev Window size in PERCENTAGE format. Upper bound = lowerBound * (1 + delta)
    uint256 public immutable delta;

    /// @dev Decimals of the returned result.
    uint8 public constant override decimals = 8;

    /// @dev Price feed description
    string public override description;

    /// @dev Constructor
    /// @param addressProvider Address of address provier which is use for getting ACL
    /// @param _delta Pre-defined window in PERCENTAGE FORMAT which is allowed for SC value
    /// @param _description Price feed description
    constructor(
        address addressProvider,
        uint256 _delta,
        string memory _description
    ) ACLTrait(addressProvider) {
        description = _description; // F:[LPF-1]
        delta = _delta; // F:[LPF-1]
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

    /// @dev Checks that value is in range [lowerBound; upperBound],
    /// Reverts if below lowerBound and returns min(value, upperBound)
    /// @param value Value to be checked and bounded
    function _checkAndUpperBoundValue(uint256 value)
        internal
        view
        returns (uint256)
    {
        uint256 lb = lowerBound;
        if (value < lb) revert ValueOutOfRangeException(); // F:[LPF-3]

        uint256 uBound = _upperBound(lb);

        return (value > uBound) ? uBound : value;
    }

    /// @dev Updates the bounds for the exchange rate value
    /// @param _lowerBound The new lower bound (the upper bound is computed dynamically)
    ///                    from the lower bound
    function setLimiter(uint256 _lowerBound)
        external
        override
        configuratorOnly // F:[LPF-4]
    {
        _setLimiter(_lowerBound); // F:[LPF-4,5]
    }

    /// @dev IMPLEMENTATION: setLimiter
    function _setLimiter(uint256 _lowerBound) internal {
        if (
            _lowerBound == 0 ||
            !_checkCurrentValueInBounds(_lowerBound, _upperBound(_lowerBound))
        ) revert IncorrectLimitsException(); // F:[LPF-4]

        lowerBound = _lowerBound; // F:[LPF-5]
        emit NewLimiterParams(lowerBound, _upperBound(_lowerBound)); // F:[LPF-5]
    }

    function _upperBound(uint256 lb) internal view returns (uint256) {
        return (lb * (PERCENTAGE_FACTOR + delta)) / PERCENTAGE_FACTOR; // F:[LPF-5]
    }

    /// @dev Returns the upper bound, calculated based on the lower bound
    function upperBound() external view returns (uint256) {
        return _upperBound(lowerBound); // F:[LPF-5]
    }

    function _checkCurrentValueInBounds(
        uint256 _lowerBound,
        uint256 _upperBound
    ) internal view virtual returns (bool);
}