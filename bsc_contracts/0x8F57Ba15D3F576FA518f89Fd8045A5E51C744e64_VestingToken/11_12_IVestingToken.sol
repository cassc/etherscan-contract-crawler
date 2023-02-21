// SPDX-License-Identifier: None
// Unvest Contracts (last updated v2.0.0) (interfaces/IVestingToken.sol)
pragma solidity 0.8.17;

/**
 * @title IVestingToken
 * @dev Interface that describes the Milestone struct and initialize function so the `VestingTokenFactory` knows how to
 * initialize the `VestingToken`.
 */
interface IVestingToken {
    /**
     * @dev Ramps describes how the periods between release tokens.
     *     - Cliff releases nothing until the end of the period.
     *     - Linear releases tokens every second according to a linear slope.
     *
     * (0) Cliff             (1) Linear
     *  |                     |
     *  |        _____        |        _____
     *  |       |             |       /
     *  |       |             |      /
     *  |_______|_____        |_____/_______
     *      T0   T1               T0   T1
     */
    enum Ramp {
        Cliff,
        Linear
    }

    /**
     * @dev `timestamp` represents a moment in time when this Milestone is considered expired.
     * @dev `ramp` defines the behaviour of the release of tokens in period between the previous Milestone and the
     * current one.
     * @dev `percentage` is the percentage of tokens that should be released once this Milestone has expired.
     */
    struct Milestone {
        uint64 timestamp;
        Ramp ramp;
        uint64 percentage;
    }

    /**
     * @notice Initializes the contract by setting up the ERC20 variables, the `underlyingToken`, and the
     * `milestonesArray` information.
     *
     * @param name                   The token collection name.
     * @param symbol                 The token collection symbol.
     * @param underlyingTokenAddress The ERC20 token that will be held by this contract.
     * @param milestonesArray        Array of all Milestones for this Contract's lifetime.
     */
    function initialize(
        string memory name,
        string memory symbol,
        address underlyingTokenAddress,
        Milestone[] calldata milestonesArray
    ) external;
}