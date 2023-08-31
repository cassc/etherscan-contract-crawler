// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IClaimCondition.sol";

/**
 *  The interface `IDropSinglePhase` is written for dmx's 'DropSinglePhase' contracts, which are distribution mechanisms for tokens.
 *
 *  An authorized wallet can set a claim condition for the distribution of the contract's tokens.
 *  A claim condition defines criteria under which accounts can mint tokens. Claim conditions can be overwritten
 *  or added to by the contract admin. At any moment, there is only one active claim condition.
 */

interface IDropSinglePhase is IClaimCondition {
    /**
     *  @param proof Prood of concerned wallet's inclusion in an allowlist.
     *  @param quantityLimitPerWallet The total quantity of tokens the allowlisted wallet is eligible to claim over time.
     *  @param price The price per token the allowlisted wallet must pay to claim tokens.
     *  @param paymentToken The paymentToken in which the allowlisted wallet must pay the price for claiming tokens.
     */
    struct AllowlistProof {
        bytes32[] proof;
        uint256 quantityLimitPerWallet;

        uint256 nftPrice;
        address paymentToken;
    }

    /// @notice Emitted when tokens are claimed via `claim`.
    event TokensClaimed(
        address indexed claimer,
        address indexed receiver,
        uint256 indexed startTokenId,
        uint256 quantityClaimed
    );

    /// @notice Emitted when the contract's claim conditions are updated.
    event ClaimConditionUpdated(ClaimCondition condition, bool resetEligibility);

    
    function claim(
        address receiver,
        uint256 quantity,
        address paymentToken,
        uint256 price,
        AllowlistProof calldata allowlistProof,
        bytes memory data
    ) external payable;

    /**
     *  @notice Lets a contract admin (account with `DEFAULT_ADMIN_ROLE`) set claim conditions.
     *
     *  @param phase                    Claim condition to set.
     *
     *  @param resetClaimEligibility    Whether to honor the restrictions applied to wallets who have claimed tokens in the current conditions,
     *                                  in the new claim conditions being set.
     */
    function setClaimConditions(ClaimCondition calldata phase, bool resetClaimEligibility) external;
}