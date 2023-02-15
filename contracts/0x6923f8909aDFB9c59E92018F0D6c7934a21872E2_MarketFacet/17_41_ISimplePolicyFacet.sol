// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { SimplePolicy, SimplePolicyInfo, PolicyCommissionsBasisPoints } from "./FreeStructs.sol";

/**
 * @title Simple Policies
 * @notice Facet for working with Simple Policies
 * @dev Simple Policy facet
 */
interface ISimplePolicyFacet {
    /**
     * @dev Generate a simple policy hash for singing by the stakeholders
     * @param _startDate Date when policy becomes active
     * @param _maturationDate Date after which policy becomes matured
     * @param _asset ID of the underlying asset, used as collateral and to pay out claims
     * @param _limit Policy coverage limit
     * @param _offchainDataHash Hash of all the important policy data stored offchain
     * @return signingHash_ hash for signing
     */
    function getSigningHash(
        uint256 _startDate,
        uint256 _maturationDate,
        bytes32 _asset,
        uint256 _limit,
        bytes32 _offchainDataHash
    ) external view returns (bytes32 signingHash_);

    /**
     * @dev Pay a premium of `_amount` on simple policy
     * @param _policyId Id of the simple policy
     * @param _amount Amount of the premium
     */
    function paySimplePremium(bytes32 _policyId, uint256 _amount) external;

    /**
     * @dev Pay a claim of `_amount` for simple policy
     * @param _claimId Id of the simple policy claim
     * @param _policyId Id of the simple policy
     * @param _insuredId Id of the insured party
     * @param _amount Amount of the claim
     */
    function paySimpleClaim(
        bytes32 _claimId,
        bytes32 _policyId,
        bytes32 _insuredId,
        uint256 _amount
    ) external;

    /**
     * @dev Get simple policy info
     * @param _id Id of the simple policy
     * @return Simple policy metadata
     */
    function getSimplePolicyInfo(bytes32 _id) external view returns (SimplePolicyInfo memory);

    /**
     * @notice Get the policy premium commissions basis points.
     * @return PolicyCommissionsBasisPoints struct containing the individual basis points set for each policy commission receiver.
     */
    function getPremiumCommissionBasisPoints() external view returns (PolicyCommissionsBasisPoints memory);

    /**
     * @dev Check and update simple policy state
     * @param _id Id of the simple policy
     */
    function checkAndUpdateSimplePolicyState(bytes32 _id) external;

    /**
     * @dev Cancel a simple policy
     * @param _policyId Id of the simple policy
     */
    function cancelSimplePolicy(bytes32 _policyId) external;
}