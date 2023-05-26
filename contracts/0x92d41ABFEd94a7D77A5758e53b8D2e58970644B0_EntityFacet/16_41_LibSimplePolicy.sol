// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { AppStorage, LibAppStorage } from "../AppStorage.sol";
import { Entity, SimplePolicy } from "../AppStorage.sol";
import { LibACL } from "./LibACL.sol";
import { LibConstants } from "./LibConstants.sol";
import { LibObject } from "./LibObject.sol";
import { LibTokenizedVault } from "./LibTokenizedVault.sol";
import { LibFeeRouter } from "./LibFeeRouter.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibEIP712 } from "src/diamonds/nayms/libs/LibEIP712.sol";

import { EntityDoesNotExist, PolicyDoesNotExist } from "src/diamonds/nayms/interfaces/CustomErrors.sol";

library LibSimplePolicy {
    event SimplePolicyMatured(bytes32 indexed id);
    event SimplePolicyCancelled(bytes32 indexed id);
    event SimplePolicyPremiumPaid(bytes32 indexed id, uint256 amount);
    event SimplePolicyClaimPaid(bytes32 indexed _claimId, bytes32 indexed policyId, bytes32 indexed insuredId, uint256 amount);

    function _getSimplePolicyInfo(bytes32 _policyId) internal view returns (SimplePolicy memory simplePolicyInfo) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        simplePolicyInfo = s.simplePolicies[_policyId];
    }

    function _checkAndUpdateState(bytes32 _policyId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        SimplePolicy storage simplePolicy = s.simplePolicies[_policyId];

        if (!simplePolicy.cancelled && block.timestamp >= simplePolicy.maturationDate && simplePolicy.fundsLocked) {
            // When the policy matures, the entity regains their capacity that was being utilized for that policy.
            releaseFunds(_policyId);

            // emit event
            emit SimplePolicyMatured(_policyId);
        }
    }

    function _payPremium(
        bytes32 _payerEntityId,
        bytes32 _policyId,
        uint256 _amount
    ) internal {
        require(_amount > 0, "invalid premium amount");

        AppStorage storage s = LibAppStorage.diamondStorage();
        if (!s.existingEntities[_payerEntityId]) {
            revert EntityDoesNotExist(_payerEntityId);
        }
        if (!s.existingSimplePolicies[_policyId]) {
            revert PolicyDoesNotExist(_policyId);
        }
        bytes32 policyEntityId = LibObject._getParent(_policyId);
        SimplePolicy storage simplePolicy = s.simplePolicies[_policyId];
        require(!simplePolicy.cancelled, "Policy is cancelled");

        LibTokenizedVault._internalTransfer(_payerEntityId, policyEntityId, simplePolicy.asset, _amount);
        LibFeeRouter._payPremiumCommissions(_policyId, _amount);

        simplePolicy.premiumsPaid += _amount;

        emit SimplePolicyPremiumPaid(_policyId, _amount);
    }

    function _payClaim(
        bytes32 _claimId,
        bytes32 _policyId,
        bytes32 _insuredEntityId,
        uint256 _amount
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(_amount > 0, "invalid claim amount");
        require(LibACL._isInGroup(_insuredEntityId, _policyId, LibHelpers._stringToBytes32(LibConstants.GROUP_INSURED_PARTIES)), "not an insured party");

        SimplePolicy storage simplePolicy = s.simplePolicies[_policyId];
        require(!simplePolicy.cancelled, "Policy is cancelled");

        uint256 claimsPaid = simplePolicy.claimsPaid;
        require(simplePolicy.limit >= _amount + claimsPaid, "exceeds policy limit");
        simplePolicy.claimsPaid += _amount;

        bytes32 entityId = LibObject._getParent(_policyId);
        Entity memory entity = s.entities[entityId];
        s.lockedBalances[entityId][entity.assetId] -= (_amount * entity.collateralRatio) / LibConstants.BP_FACTOR;

        s.entities[entityId].utilizedCapacity -= (_amount * entity.collateralRatio) / LibConstants.BP_FACTOR;

        LibObject._createObject(_claimId);

        LibTokenizedVault._internalTransfer(entityId, _insuredEntityId, simplePolicy.asset, _amount);

        emit SimplePolicyClaimPaid(_claimId, _policyId, _insuredEntityId, _amount);
    }

    function _cancel(bytes32 _policyId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        SimplePolicy storage simplePolicy = s.simplePolicies[_policyId];
        require(!simplePolicy.cancelled, "Policy already cancelled");

        releaseFunds(_policyId);
        simplePolicy.cancelled = true;

        emit SimplePolicyCancelled(_policyId);
    }

    function releaseFunds(bytes32 _policyId) private {
        AppStorage storage s = LibAppStorage.diamondStorage();
        bytes32 entityId = LibObject._getParent(_policyId);

        SimplePolicy storage simplePolicy = s.simplePolicies[_policyId];
        Entity storage entity = s.entities[entityId];

        uint256 policyLockedAmount = ((simplePolicy.limit - simplePolicy.claimsPaid) * entity.collateralRatio) / LibConstants.BP_FACTOR;
        entity.utilizedCapacity -= policyLockedAmount;
        s.lockedBalances[entityId][entity.assetId] -= policyLockedAmount;

        simplePolicy.fundsLocked = false;
    }

    function _getSigningHash(
        uint256 _startDate,
        uint256 _maturationDate,
        bytes32 _asset,
        uint256 _limit,
        bytes32 _offchainDataHash
    ) internal view returns (bytes32) {
        return
            LibEIP712._hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("SimplePolicy(uint256 startDate,uint256 maturationDate,bytes32 asset,uint256 limit,bytes32 offchainDataHash)"),
                        _startDate,
                        _maturationDate,
                        _asset,
                        _limit,
                        _offchainDataHash
                    )
                )
            );
    }
}