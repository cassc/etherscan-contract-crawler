// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Modifiers } from "../Modifiers.sol";
import { Entity, SimplePolicy, PolicyCommissionsBasisPoints } from "../AppStorage.sol";
import { LibObject } from "../libs/LibObject.sol";
import { LibHelpers } from "../libs/LibHelpers.sol";
import { LibSimplePolicy } from "../libs/LibSimplePolicy.sol";
import { LibFeeRouter } from "../libs/LibFeeRouter.sol";
import { ISimplePolicyFacet } from "../interfaces/ISimplePolicyFacet.sol";

/**
 * @title Simple Policies
 * @notice Facet for working with Simple Policies
 * @dev Simple Policy facet
 */
contract SimplePolicyFacet is ISimplePolicyFacet, Modifiers {
    /**
     * @dev Pay a premium of `_amount` on simple policy
     * @param _policyId Id of the simple policy
     * @param _amount Amount of the premium
     */
    function paySimplePremium(bytes32 _policyId, uint256 _amount) external notLocked(msg.sig) assertPolicyHandler(_policyId) {
        bytes32 senderId = LibHelpers._getIdForAddress(msg.sender);
        bytes32 payerEntityId = LibObject._getParent(senderId);

        LibSimplePolicy._payPremium(payerEntityId, _policyId, _amount);
    }

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
    ) external notLocked(msg.sig) assertSysMgr {
        LibSimplePolicy._payClaim(_claimId, _policyId, _insuredId, _amount);
    }

    /**
     * @dev Get simple policy info
     * @param _policyId Id of the simple policy
     * @return Simple policy metadata
     */
    function getSimplePolicyInfo(bytes32 _policyId) external view returns (SimplePolicy memory) {
        return LibSimplePolicy._getSimplePolicyInfo(_policyId);
    }

    function getPremiumCommissionBasisPoints() external view returns (PolicyCommissionsBasisPoints memory bp) {
        bp = LibFeeRouter._getPremiumCommissionBasisPoints();
    }

    /**
     * @dev Check and update simple policy state
     * @param _policyId Id of the simple policy
     */
    function checkAndUpdateSimplePolicyState(bytes32 _policyId) external notLocked(msg.sig) {
        LibSimplePolicy._checkAndUpdateState(_policyId);
    }

    /**
     * @dev Cancel a simple policy
     * @param _policyId Id of the simple policy
     */
    function cancelSimplePolicy(bytes32 _policyId) external assertSysMgr {
        LibSimplePolicy._cancel(_policyId);
    }

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
    ) external view returns (bytes32 signingHash_) {
        signingHash_ = LibSimplePolicy._getSigningHash(_startDate, _maturationDate, _asset, _limit, _offchainDataHash);
    }
}