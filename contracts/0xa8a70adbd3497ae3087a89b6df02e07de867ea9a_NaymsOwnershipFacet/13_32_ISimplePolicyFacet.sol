// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { SimplePolicyInfo, SimplePolicy, CalculatedFees } from "./FreeStructs.sol";

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
     * @dev Get the list of commission receivers
     * @param _id Id of the simple policy
     * @return commissionReceivers
     */
    function getPolicyCommissionReceivers(bytes32 _id) external returns (bytes32[] memory commissionReceivers);

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

    /**
     * @dev Calculate the policy premium fees based on a buy amount.
     * @param _premiumPaid The amount that the fees payments are calculated from.
     * @return cf CalculatedFees struct
     */
    function calculatePremiumFees(bytes32 _policyId, uint256 _premiumPaid) external view returns (CalculatedFees memory cf);
}