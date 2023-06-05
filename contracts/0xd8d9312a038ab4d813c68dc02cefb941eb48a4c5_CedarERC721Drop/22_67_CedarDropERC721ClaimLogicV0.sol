// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.7;

import "../types/DataTypes.sol";
import "../errors/IErrors.sol";

import "../lib/CurrencyTransferLib.sol";
import "../lib/MerkleProof.sol";

library CedarDropERC721ClaimLogicV0 {
    using CedarDropERC721ClaimLogicV0 for DataTypes.ClaimData;
    using BitMapsUpgradeable for BitMapsUpgradeable.BitMap;

    struct InternalClaim {
        bool validMerkleProof;
        uint256 merkleProofIndex;
        bool toVerifyMaxQuantityPerTransaction;
        uint256 activeConditionId;
        uint256 tokenIdToClaim;
    }

    event TokensClaimed(
        uint256 indexed claimConditionIndex,
        address indexed claimer,
        address indexed receiver,
        uint256 startTokenId,
        uint256 quantityClaimed
    );

    event ClaimConditionsUpdated(IDropClaimConditionV0.ClaimCondition[] claimConditions);

    function transferClaimedTokens(
        DataTypes.ClaimData storage claimData,
        uint256 _conditionId,
        uint256 _quantityBeingClaimed,
        address msgSender
    ) public returns (uint256[] memory tokens) {
        // Update the supply minted under mint condition.
        claimData.claimCondition.phases[_conditionId].supplyClaimed += _quantityBeingClaimed;

        // if transfer claimed tokens is called when `to != msg.sender`, it'd use msg.sender's limits.
        // behavior would be similar to `msg.sender` mint for itself, then transfer to `_to`.
        claimData.claimCondition.limitLastClaimTimestamp[_conditionId][msgSender] = block.timestamp;
        claimData.walletClaimCount[msgSender] += _quantityBeingClaimed;

        uint256 tokenIdToClaim = claimData.nextTokenIdToClaim;

        tokens = new uint256[](_quantityBeingClaimed);

        for (uint256 i = 0; i < _quantityBeingClaimed; i += 1) {
            tokens[i] = tokenIdToClaim;
            tokenIdToClaim += 1;
        }

        claimData.nextTokenIdToClaim = tokenIdToClaim;
    }

    function executeClaim(
        DataTypes.ClaimData storage claimData,
        address _receiver,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bytes32[] calldata _proofs,
        uint256 _proofMaxQuantityPerTransaction,
        address msgSender
    ) public returns (uint256[] memory) {
        InternalClaim memory internalData;

        internalData.tokenIdToClaim = claimData.nextTokenIdToClaim;

        // Get the claim conditions.
        internalData.activeConditionId = getActiveClaimConditionId(claimData);

        /**
         *  We make allowlist checks (i.e. verifyClaimMerkleProof) before verifying the claim's general
         *  validity (i.e. verifyClaim) because we give precedence to the check of allow list quantity
         *  restriction over the check of the general claim condition's quantityLimitPerTransaction
         *  restriction.
         */

        // Verify inclusion in allowlist.
        (internalData.validMerkleProof, internalData.merkleProofIndex) = verifyClaimMerkleProof(
            claimData,
            internalData.activeConditionId,
            msgSender,
            _quantity,
            _proofs,
            _proofMaxQuantityPerTransaction
        );

        // Verify claim validity. If not valid, revert.
        // when there's allowlist present --> verifyClaimMerkleProof will verify the _proofMaxQuantityPerTransaction value with hashed leaf in the allowlist
        // when there's no allowlist, this check is true --> verifyClaim will check for _quantity being less/equal than the limit
        internalData.toVerifyMaxQuantityPerTransaction =
            _proofMaxQuantityPerTransaction == 0 ||
            claimData.claimCondition.phases[internalData.activeConditionId].merkleRoot == bytes32(0);
        verifyClaim(
            claimData,
            internalData.activeConditionId,
            msgSender,
            _quantity,
            _currency,
            _pricePerToken,
            internalData.toVerifyMaxQuantityPerTransaction
        );

        if (internalData.validMerkleProof && _proofMaxQuantityPerTransaction > 0) {
            /**
             *  Mark the claimer's use of their position in the allowlist. A spot in an allowlist
             *  can be used only once.
             */
            claimData.claimCondition.limitMerkleProofClaim[internalData.activeConditionId].set(
                internalData.merkleProofIndex
            );
        }

        // If there's a price, collect price.
        claimData.collectClaimPrice(_quantity, _currency, _pricePerToken, msgSender);

        // Mint the relevant NFTs to claimer.
        uint256[] memory tokens = transferClaimedTokens(
            claimData,
            internalData.activeConditionId,
            _quantity,
            msgSender
        );

        emit TokensClaimed(
            internalData.activeConditionId,
            msgSender,
            _receiver,
            internalData.tokenIdToClaim,
            _quantity
        );

        return tokens;
    }

    function verifyClaimMerkleProof(
        DataTypes.ClaimData storage claimData,
        uint256 _conditionId,
        address _claimer,
        uint256 _quantity,
        bytes32[] calldata _proofs,
        uint256 _proofMaxQuantityPerTransaction
    ) public view returns (bool validMerkleProof, uint256 merkleProofIndex) {
        IDropClaimConditionV0.ClaimCondition memory currentClaimPhase = claimData.claimCondition.phases[_conditionId];

        if (currentClaimPhase.merkleRoot != bytes32(0)) {
            (validMerkleProof, merkleProofIndex) = MerkleProof.verify(
                _proofs,
                currentClaimPhase.merkleRoot,
                keccak256(abi.encodePacked(_claimer, _proofMaxQuantityPerTransaction))
            );

            if (!validMerkleProof) revert InvalidProof();
            if (!(!claimData.claimCondition.limitMerkleProofClaim[_conditionId].get(merkleProofIndex)))
                revert InvalidProof();
            if (!(_proofMaxQuantityPerTransaction == 0 || _quantity <= _proofMaxQuantityPerTransaction))
                revert InvalidProof();
        }
    }

    function getActiveClaimConditionId(DataTypes.ClaimData storage claimData) public view returns (uint256) {
        for (
            uint256 i = claimData.claimCondition.currentStartId + claimData.claimCondition.count;
            i > claimData.claimCondition.currentStartId;
            i--
        ) {
            if (block.timestamp >= claimData.claimCondition.phases[i - 1].startTimestamp) {
                return i - 1;
            }
        }

        revert("!CONDITION.");
    }

    function verifyClaim(
        DataTypes.ClaimData storage claimData,
        uint256 _conditionId,
        address _claimer,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bool verifyMaxQuantityPerTransaction
    ) public view {
        IDropClaimConditionV0.ClaimCondition memory currentClaimPhase = claimData.claimCondition.phases[_conditionId];

        if (!(_currency == currentClaimPhase.currency && _pricePerToken == currentClaimPhase.pricePerToken))
            revert InvalidPrice();
        // If we're checking for an allowlist quantity restriction, ignore the general quantity restriction.
        if (
            !(_quantity > 0 &&
                (!verifyMaxQuantityPerTransaction || _quantity <= currentClaimPhase.quantityLimitPerTransaction))
        ) revert InvalidQuantity();
        if (!(currentClaimPhase.supplyClaimed + _quantity <= currentClaimPhase.maxClaimableSupply))
            revert CrossedLimit();
        if (!(claimData.nextTokenIdToClaim + _quantity <= claimData.nextTokenIdToMint)) revert CrossedLimit();
        if (!(claimData.maxTotalSupply == 0 || claimData.nextTokenIdToClaim + _quantity <= claimData.maxTotalSupply))
            revert CrossedLimit();
        if (
            !(claimData.maxWalletClaimCount == 0 ||
                claimData.walletClaimCount[_claimer] + _quantity <= claimData.maxWalletClaimCount)
        ) revert CrossedLimit();
        (uint256 lastClaimTimestamp, uint256 nextValidClaimTimestamp) = getClaimTimestamp(
            claimData,
            _conditionId,
            _claimer
        );
        if (!(lastClaimTimestamp == 0 || block.timestamp >= nextValidClaimTimestamp)) revert InvalidTime();
    }

    /// @dev Returns the timestamp for when a claimer is eligible for claiming NFTs again.
    function getClaimTimestamp(
        DataTypes.ClaimData storage claimData,
        uint256 _conditionId,
        address _claimer
    ) public view returns (uint256 lastClaimTimestamp, uint256 nextValidClaimTimestamp) {
        lastClaimTimestamp = claimData.claimCondition.limitLastClaimTimestamp[_conditionId][_claimer];

        unchecked {
            nextValidClaimTimestamp =
                lastClaimTimestamp +
                claimData.claimCondition.phases[_conditionId].waitTimeInSecondsBetweenClaims;

            if (nextValidClaimTimestamp < lastClaimTimestamp) {
                nextValidClaimTimestamp = type(uint256).max;
            }
        }
    }

    /// @dev Collects and distributes the primary sale value of NFTs being claimed.
    function collectClaimPrice(
        DataTypes.ClaimData storage claimData,
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken,
        address msgSender
    ) internal {
        if (_pricePerToken == 0) {
            return;
        }

        uint256 MAX_BPS = 10_000;

        uint256 totalPrice = _quantityToClaim * _pricePerToken;
        uint256 platformFees = (totalPrice * claimData.platformFeeBps) / MAX_BPS;

        if(_currency == CurrencyTransferLib.NATIVE_TOKEN && !(msg.value == totalPrice)) revert InvalidPrice();

        CurrencyTransferLib.transferCurrency(_currency, msgSender, claimData.platformFeeRecipient, platformFees);
        CurrencyTransferLib.transferCurrency(_currency, msgSender, claimData.primarySaleRecipient, totalPrice - platformFees);
    }

    /// @dev Lets a contract admin (account with `DEFAULT_ADMIN_ROLE`) set claim conditions.
    function setClaimConditions(
        DataTypes.ClaimData storage claimData,
        IDropClaimConditionV0.ClaimCondition[] calldata _phases,
        bool _resetClaimEligibility
    ) public {
        uint256 existingStartIndex = claimData.claimCondition.currentStartId;
        uint256 existingPhaseCount = claimData.claimCondition.count;

        /**
         *  `limitLastClaimTimestamp` and `limitMerkleProofClaim` are mappings that use a
         *  claim condition's UID as a key.
         *
         *  If `_resetClaimEligibility == true`, we assign completely new UIDs to the claim
         *  conditions in `_phases`, effectively resetting the restrictions on claims expressed
         *  by `limitLastClaimTimestamp` and `limitMerkleProofClaim`.
         */
        uint256 newStartIndex = existingStartIndex;
        if (_resetClaimEligibility) {
            newStartIndex = existingStartIndex + existingPhaseCount;
        }

        claimData.claimCondition.count = _phases.length;
        claimData.claimCondition.currentStartId = newStartIndex;

        uint256 lastConditionStartTimestamp;
        for (uint256 i = 0; i < _phases.length; i++) {
            if (!(i == 0 || lastConditionStartTimestamp < _phases[i].startTimestamp)) revert ST();

            uint256 supplyClaimedAlready = claimData.claimCondition.phases[newStartIndex + i].supplyClaimed;

            if (!(supplyClaimedAlready <= _phases[i].maxClaimableSupply)) revert CrossedLimit();

            claimData.claimCondition.phases[newStartIndex + i] = _phases[i];
            claimData.claimCondition.phases[newStartIndex + i].supplyClaimed = supplyClaimedAlready;

            lastConditionStartTimestamp = _phases[i].startTimestamp;
        }

        /**
         *  Gas refunds (as much as possible)
         *
         *  If `_resetClaimEligibility == true`, we assign completely new UIDs to the claim
         *  conditions in `_phases`. So, we delete claim conditions with UID < `newStartIndex`.
         *
         *  If `_resetClaimEligibility == false`, and there are more existing claim conditions
         *  than in `_phases`, we delete the existing claim conditions that don't get replaced
         *  by the conditions in `_phases`.
         */
        if (_resetClaimEligibility) {
            for (uint256 i = existingStartIndex; i < newStartIndex; i++) {
                delete claimData.claimCondition.phases[i];
                delete claimData.claimCondition.limitMerkleProofClaim[i];
            }
        } else {
            if (existingPhaseCount > _phases.length) {
                for (uint256 i = _phases.length; i < existingPhaseCount; i++) {
                    delete claimData.claimCondition.phases[newStartIndex + i];
                    delete claimData.claimCondition.limitMerkleProofClaim[newStartIndex + i];
                }
            }
        }

        emit ClaimConditionsUpdated(_phases);
    }

    function getActiveClaimConditions(DataTypes.ClaimData storage claimData)
        public
        view
        returns (
            IDropClaimConditionV0.ClaimCondition memory condition,
            uint256 conditionId,
            uint256 walletMaxClaimCount,
            uint256 remainingSupply
        )
    {
        conditionId = getActiveClaimConditionId(claimData);
        condition = claimData.claimCondition.phases[conditionId];
        walletMaxClaimCount = claimData.maxWalletClaimCount;
        remainingSupply = 0; // @todo
    }

    function getUserClaimConditions(DataTypes.ClaimData storage claimData, address _claimer)
        public
        view
        returns (
            uint256 conditionId,
            uint256 walletClaimedCount,
            uint256 lastClaimTimestamp,
            uint256 nextValidClaimTimestamp
        )
    {
        conditionId = getActiveClaimConditionId(claimData);
        (lastClaimTimestamp, nextValidClaimTimestamp) = getClaimTimestamp(claimData, conditionId, _claimer);
        walletClaimedCount = claimData.walletClaimCount[_claimer];
    }
}