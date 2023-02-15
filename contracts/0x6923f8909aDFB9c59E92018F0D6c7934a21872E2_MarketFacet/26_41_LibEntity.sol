// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { LibAppStorage, AppStorage } from "../AppStorage.sol";
import { Entity, SimplePolicy, Stakeholders } from "../AppStorage.sol";
import { LibConstants } from "./LibConstants.sol";
import { LibAdmin } from "./LibAdmin.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibObject } from "./LibObject.sol";
import { LibACL } from "./LibACL.sol";
import { LibTokenizedVault } from "./LibTokenizedVault.sol";
import { LibMarket } from "./LibMarket.sol";
import { LibSimplePolicy } from "./LibSimplePolicy.sol";
import { LibEIP712 } from "src/diamonds/nayms/libs/LibEIP712.sol";

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { EntityDoesNotExist, DuplicateSignerCreatingSimplePolicy, PolicyIdCannotBeZero, ObjectCannotBeTokenized, CreatingEntityThatAlreadyExists, SimplePolicyStakeholderSignatureInvalid, SimplePolicyClaimsPaidShouldStartAtZero, SimplePolicyPremiumsPaidShouldStartAtZero, CancelCannotBeTrueWhenCreatingSimplePolicy, UtilizedCapacityGreaterThanMaxCapacity } from "src/diamonds/nayms/interfaces/CustomErrors.sol";

library LibEntity {
    using ECDSA for bytes32;
    /**
     * @notice New entity has been created
     * @dev Thrown when entity is created
     * @param entityId Unique ID for the entity
     * @param entityAdmin Unique ID of the entity administrator
     */
    event EntityCreated(bytes32 indexed entityId, bytes32 entityAdmin);
    event EntityUpdated(bytes32 indexed entityId);
    event SimplePolicyCreated(bytes32 indexed id, bytes32 entityId);
    event TokenSaleStarted(bytes32 indexed entityId, uint256 offerId, string tokenSymbol, string tokenName);
    event CollateralRatioUpdated(bytes32 indexed entityId, uint256 collateralRatio, uint256 utilizedCapacity);

    /**
     * @dev If an entity passes their checks to create a policy, ensure that the entity's capacity is appropriately decreased by the amount of capital that will be tied to the new policy being created.
     */
    function _validateSimplePolicyCreation(bytes32 _entityId, SimplePolicy calldata simplePolicy) internal view {
        // The policy's limit cannot be 0. If a policy's limit is zero, this essentially means the policy doesn't require any capital, which doesn't make business sense.
        require(simplePolicy.limit > 0, "limit not > 0");
        require(LibAdmin._isSupportedExternalToken(simplePolicy.asset), "external token is not supported");

        if (simplePolicy.claimsPaid != 0) {
            revert SimplePolicyClaimsPaidShouldStartAtZero();
        }
        if (simplePolicy.premiumsPaid != 0) {
            revert SimplePolicyPremiumsPaidShouldStartAtZero();
        }
        if (simplePolicy.cancelled) {
            revert CancelCannotBeTrueWhenCreatingSimplePolicy();
        }
        AppStorage storage s = LibAppStorage.diamondStorage();
        Entity memory entity = s.entities[_entityId];

        require(LibAdmin._isSupportedExternalToken(simplePolicy.asset), "external token is not supported");
        require(simplePolicy.asset == entity.assetId, "asset not matching with entity");

        // Calculate the entity's utilized capacity after it writes this policy.
        uint256 updatedUtilizedCapacity = entity.utilizedCapacity + ((simplePolicy.limit * entity.collateralRatio) / LibConstants.BP_FACTOR);

        // The entity must have enough capacity available to write this policy.
        // An entity is not able to write an additional policy that will utilize its capacity beyond its assigned max capacity.
        require(entity.maxCapacity >= updatedUtilizedCapacity, "not enough available capacity");

        // The entity's balance must be >= to the updated capacity requirement
        // todo: business only wants to count the entity's balance that was raised from the participation token sale and not its total balance
        require(LibTokenizedVault._internalBalanceOf(_entityId, simplePolicy.asset) >= updatedUtilizedCapacity, "not enough capital");

        require(simplePolicy.startDate >= block.timestamp, "start date < block.timestamp");
        require(simplePolicy.maturationDate > simplePolicy.startDate, "start date > maturation date");

        uint256 commissionReceiversArrayLength = simplePolicy.commissionReceivers.length;
        require(commissionReceiversArrayLength > 0, "must have commission receivers");

        uint256 commissionBasisPointsArrayLength = simplePolicy.commissionBasisPoints.length;
        require(commissionBasisPointsArrayLength > 0, "must have commission basis points");
        require(commissionReceiversArrayLength == commissionBasisPointsArrayLength, "commissions lengths !=");

        uint256 totalBP;
        for (uint256 i; i < commissionBasisPointsArrayLength; ++i) {
            totalBP += simplePolicy.commissionBasisPoints[i];
        }
        require(totalBP <= LibConstants.BP_FACTOR, "bp cannot be > 10000");
    }

    function _createSimplePolicy(
        bytes32 _policyId,
        bytes32 _entityId,
        Stakeholders calldata _stakeholders,
        SimplePolicy calldata _simplePolicy,
        bytes32 _offchainDataHash
    ) internal {
        if (_policyId == 0) {
            revert PolicyIdCannotBeZero();
        }

        AppStorage storage s = LibAppStorage.diamondStorage();
        if (!s.existingEntities[_entityId]) {
            revert EntityDoesNotExist(_entityId);
        }
        require(_stakeholders.entityIds.length == _stakeholders.signatures.length, "incorrect number of signatures");

        _validateSimplePolicyCreation(_entityId, _simplePolicy);

        Entity storage entity = s.entities[_entityId];
        uint256 factoredLimit = (_simplePolicy.limit * entity.collateralRatio) / LibConstants.BP_FACTOR;

        entity.utilizedCapacity += factoredLimit;
        s.lockedBalances[_entityId][entity.assetId] += factoredLimit;

        // hash contents are implicitlly checked by making sure that resolved signer is the stakeholder entity's admin
        bytes32 signingHash = LibSimplePolicy._getSigningHash(_simplePolicy.startDate, _simplePolicy.maturationDate, _simplePolicy.asset, _simplePolicy.limit, _offchainDataHash);

        LibObject._createObject(_policyId, _entityId, signingHash);
        s.simplePolicies[_policyId] = _simplePolicy;
        s.simplePolicies[_policyId].fundsLocked = true;

        uint256 rolesCount = _stakeholders.roles.length;
        address signer;
        address previousSigner;

        for (uint256 i = 0; i < rolesCount; i++) {
            previousSigner = signer;

            signer = ECDSA.recover(ECDSA.toEthSignedMessageHash(signingHash), _stakeholders.signatures[i]);

            // Ensure there are no duplicate signers.
            if (previousSigner >= signer) {
                revert DuplicateSignerCreatingSimplePolicy(previousSigner, signer);
            }

            if (LibObject._getParentFromAddress(signer) != _stakeholders.entityIds[i]) {
                revert SimplePolicyStakeholderSignatureInvalid(
                    signingHash,
                    _stakeholders.signatures[i],
                    LibHelpers._getIdForAddress(signer),
                    LibObject._getParentFromAddress(signer),
                    _stakeholders.entityIds[i]
                );
            }
            LibACL._assignRole(_stakeholders.entityIds[i], _policyId, _stakeholders.roles[i]);
        }

        s.existingSimplePolicies[_policyId] = true;
        emit SimplePolicyCreated(_policyId, _entityId);
    }

    /// @param _amount the amount of entity token that is minted and put on sale
    /// @param _totalPrice the buy amount
    function _startTokenSale(
        bytes32 _entityId,
        uint256 _amount,
        uint256 _totalPrice
    ) internal {
        require(_amount > 0, "mint amount must be > 0");
        require(_totalPrice > 0, "total price must be > 0");
        require(LibObject._isObjectTokenizable(_entityId), "must be tokenizable");

        AppStorage storage s = LibAppStorage.diamondStorage();

        if (!s.existingEntities[_entityId]) {
            revert EntityDoesNotExist(_entityId);
        }

        if (!LibObject._isObjectTokenizable(_entityId)) {
            revert ObjectCannotBeTokenized(_entityId);
        }

        Entity memory entity = s.entities[_entityId];

        // note: The participation tokens of the entity are minted to the entity. The participation tokens minted have the same ID as the entity.
        LibTokenizedVault._internalMint(_entityId, _entityId, _amount);

        (uint256 offerId, , ) = LibMarket._executeLimitOffer(_entityId, _entityId, _amount, entity.assetId, _totalPrice, LibConstants.FEE_SCHEDULE_STANDARD);

        emit TokenSaleStarted(_entityId, offerId, s.objectTokenSymbol[_entityId], s.objectTokenName[_entityId]);
    }

    function _createEntity(
        bytes32 _entityId,
        bytes32 _entityAdmin,
        Entity memory _entity,
        bytes32 _dataHash
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        if (s.existingEntities[_entityId]) {
            revert CreatingEntityThatAlreadyExists(_entityId);
        }
        validateEntity(_entity);

        LibObject._createObject(_entityId, _dataHash);
        LibObject._setParent(_entityAdmin, _entityId);
        s.existingEntities[_entityId] = true;

        LibACL._assignRole(_entityAdmin, _entityId, LibHelpers._stringToBytes32(LibConstants.ROLE_ENTITY_ADMIN));

        // An entity starts without any capacity being utilized
        require(_entity.utilizedCapacity == 0, "utilized capacity starts at 0");

        s.entities[_entityId] = _entity;

        emit EntityCreated(_entityId, _entityAdmin);
    }

    function _updateEntity(bytes32 _entityId, Entity memory _entity) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // Cannot update a non-existing entity's metadata.
        if (!s.existingEntities[_entityId]) {
            revert EntityDoesNotExist(_entityId);
        }

        validateEntity(_entity);

        uint256 oldCollateralRatio = s.entities[_entityId].collateralRatio;
        uint256 oldUtilizedCapacity = s.entities[_entityId].utilizedCapacity;
        bytes32 originalAssetId = s.entities[_entityId].assetId;

        s.entities[_entityId] = _entity;
        s.entities[_entityId].assetId = originalAssetId; // assetId change not allowed

        // if it's a cell, and collateral ratio changed
        if (_entity.assetId != 0 && _entity.collateralRatio != oldCollateralRatio) {
            uint256 newUtilizedCapacity = (oldUtilizedCapacity * _entity.collateralRatio) / oldCollateralRatio;
            uint256 newLockedBalance = s.lockedBalances[_entityId][_entity.assetId] - oldUtilizedCapacity + newUtilizedCapacity;

            require(LibTokenizedVault._internalBalanceOf(_entityId, _entity.assetId) >= newLockedBalance, "collateral ratio invalid, not enough balance");

            s.entities[_entityId].utilizedCapacity = newUtilizedCapacity;
            s.lockedBalances[_entityId][_entity.assetId] = newLockedBalance;

            emit CollateralRatioUpdated(_entityId, _entity.collateralRatio, s.entities[_entityId].utilizedCapacity);
        }

        emit EntityUpdated(_entityId);
    }

    function validateEntity(Entity memory _entity) internal view {
        if (_entity.assetId != 0) {
            // entity has an underlying asset, which means it's a cell

            // External token must be whitelisted by the platform
            require(LibAdmin._isSupportedExternalToken(_entity.assetId), "external token is not supported");

            // Collateral ratio must be in acceptable range of 1 to 10000 basis points (0.01% to 100% collateralized).
            // Cannot ever be completely uncollateralized (0 basis points), if entity is a cell.
            require(1 <= _entity.collateralRatio && _entity.collateralRatio <= LibConstants.BP_FACTOR, "collateral ratio should be 1 to 10000");

            // Max capacity is the capital amount that an entity can write across all of their policies.
            // note: We do not directly use the value maxCapacity to determine if the entity can or cannot write a policy.
            //       First, we use the bool simplePolicyEnabled to toggle (enable / disable) whether an entity can or cannot write a policy.
            //       If an entity has this set to true, then we check if an entity has enough capacity to write a policy.
            require(!_entity.simplePolicyEnabled || (_entity.maxCapacity > 0), "max capacity should be greater than 0 for policy creation");

            if (_entity.utilizedCapacity > _entity.maxCapacity) {
                revert UtilizedCapacityGreaterThanMaxCapacity(_entity.utilizedCapacity, _entity.maxCapacity);
            }
        } else {
            // non-cell entity
            require(_entity.collateralRatio == 0, "only cell has collateral ratio");
            require(!_entity.simplePolicyEnabled, "only cell can issue policies");
            require(_entity.maxCapacity == 0, "only cells have max capacity");
        }
    }

    function _getEntityInfo(bytes32 _entityId) internal view returns (Entity memory entity) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        entity = s.entities[_entityId];
    }

    function _isEntity(bytes32 _entityId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.existingEntities[_entityId];
    }
}