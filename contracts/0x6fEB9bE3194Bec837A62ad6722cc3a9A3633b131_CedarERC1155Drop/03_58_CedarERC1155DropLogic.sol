// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

import "./lib/CurrencyTransferLib.sol";
import "./lib/MerkleProof.sol";
import "./types/DropERC1155DataTypes.sol";
import "./errors/IErrors.sol";
import "./../api/issuance/IDropClaimCondition.sol";

library CedarERC1155DropLogic {
    using CedarERC1155DropLogic for DropERC1155DataTypes.ClaimData;

    uint256 private constant MAX_UINT256 = 2**256 - 1;

    struct InternalClaim {
        bool validMerkleProof;
        uint256 merkleProofIndex;
        bool toVerifyMaxQuantityPerTransaction;
        uint256 activeConditionId;
        uint256 tokenIdToClaim;
    }

    function setClaimConditions(
        DropERC1155DataTypes.ClaimData storage claimData,
        uint256 _tokenId,
        IDropClaimConditionV0.ClaimCondition[] calldata _phases,
        bool _resetClaimEligibility
    ) external {
        IDropClaimConditionV0.ClaimConditionList storage condition = claimData.claimCondition[_tokenId];
        uint256 existingStartIndex = condition.currentStartId;
        uint256 existingPhaseCount = condition.count;

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

        condition.count = _phases.length;
        condition.currentStartId = newStartIndex;

        uint256 lastConditionStartTimestamp;
        for (uint256 i = 0; i < _phases.length; i++) {
            if (!(i == 0 || lastConditionStartTimestamp < _phases[i].startTimestamp)) revert InvalidTime();

            uint256 supplyClaimedAlready = condition.phases[newStartIndex + i].supplyClaimed;

            if (!(supplyClaimedAlready <= _phases[i].maxClaimableSupply)) revert CrossedLimitMaxClaimableSupply();

            condition.phases[newStartIndex + i] = _phases[i];
            condition.phases[newStartIndex + i].supplyClaimed = supplyClaimedAlready;

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
                delete condition.phases[i];
            }
        } else {
            if (existingPhaseCount > _phases.length) {
                for (uint256 i = _phases.length; i < existingPhaseCount; i++) {
                    delete condition.phases[newStartIndex + i];
                }
            }
        }
    }

    function executeClaim(
        DropERC1155DataTypes.ClaimData storage claimData,
        uint256 _tokenId,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bytes32[] calldata _proofs,
        uint256 _proofMaxQuantityPerTransaction,
        address msgSender,
        address primarySaleRecipient
    ) public returns (InternalClaim memory internalData) {
        // Get the active claim condition index.
        internalData.activeConditionId = getActiveClaimConditionId(claimData, _tokenId);

        /**
         *  We make allowlist checks (i.e. verifyClaimMerkleProof) before verifying the claim's general
         *  validity (i.e. verifyClaim) because we give precedence to the check of allow list quantity
         *  restriction over the check of the general claim condition's quantityLimitPerTransaction
         *  restriction.
         */
        (internalData.validMerkleProof, internalData.merkleProofIndex) = verifyClaimMerkleProof(
            claimData,
            internalData.activeConditionId,
            msgSender,
            _tokenId,
            _quantity,
            _proofs,
            _proofMaxQuantityPerTransaction
        );

        // Verify claim validity. If not valid, revert.
        // when there's allowlist present --> verifyClaimMerkleProof will verify the _proofMaxQuantityPerTransaction value with hashed leaf in the allowlist
        // when there's no allowlist, this check is true --> verifyClaim will check for _quantity being less/equal than the limit
        internalData.toVerifyMaxQuantityPerTransaction =
            _proofMaxQuantityPerTransaction == 0 ||
            claimData.claimCondition[_tokenId].phases[internalData.activeConditionId].merkleRoot == bytes32(0);

        verifyClaim(
            claimData,
            internalData.activeConditionId,
            msgSender,
            _tokenId,
            _quantity,
            _currency,
            _pricePerToken,
            internalData.toVerifyMaxQuantityPerTransaction
        );

        // If there's a price, collect price.
        collectClaimPrice(claimData, _quantity, _currency, _pricePerToken, _tokenId, msgSender, primarySaleRecipient);

        // Book-keeping before the calling contract does the actual transfer and mint the relevant NFTs to claimer.
        recordTransferClaimedTokens(claimData, internalData.activeConditionId, _tokenId, _quantity, msgSender);
    }

    /// @dev Verify inclusion in allow-list.
    function verifyClaimMerkleProof(
        DropERC1155DataTypes.ClaimData storage claimData,
        uint256 _conditionId,
        address _claimer,
        uint256 _tokenId,
        uint256 _quantity,
        bytes32[] calldata _proofs,
        uint256 _proofMaxQuantityPerTransaction
    ) public view returns (bool validMerkleProof, uint256 merkleProofIndex) {
        IDropClaimConditionV0.ClaimCondition memory currentClaimPhase = claimData.claimCondition[_tokenId].phases[
            _conditionId
        ];

        if (currentClaimPhase.merkleRoot != bytes32(0)) {
            (validMerkleProof, merkleProofIndex) = MerkleProof.verify(
                _proofs,
                currentClaimPhase.merkleRoot,
                keccak256(abi.encodePacked(_claimer, _proofMaxQuantityPerTransaction))
            );

            if (!validMerkleProof) revert InvalidMerkleProof();
            if (
                !(_proofMaxQuantityPerTransaction == 0 ||
                    _quantity <=
                    _proofMaxQuantityPerTransaction -
                        claimData.claimCondition[_tokenId].userClaims[_conditionId][_claimer].claimedBalance)
            ) revert InvalidMaxQuantityProof();
        }
    }

    /// @dev Checks a request to claim NFTs against the active claim condition's criteria.
    function verifyClaim(
        DropERC1155DataTypes.ClaimData storage claimData,
        uint256 _conditionId,
        address _claimer,
        uint256 _tokenId,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bool verifyMaxQuantityPerTransaction
    ) public view {
        IDropClaimConditionV0.ClaimCondition memory currentClaimPhase = claimData.claimCondition[_tokenId].phases[
            _conditionId
        ];

        if (!(_currency == currentClaimPhase.currency && _pricePerToken == currentClaimPhase.pricePerToken)) {
            revert InvalidPrice();
        }
        if (
            !(_quantity > 0 &&
                (!verifyMaxQuantityPerTransaction || _quantity <= currentClaimPhase.quantityLimitPerTransaction))
        ) {
            revert CrossedLimitQuantityPerTransaction();
        }

        if (!(currentClaimPhase.supplyClaimed + _quantity <= currentClaimPhase.maxClaimableSupply)) {
            revert CrossedLimitMaxClaimableSupply();
        }
        if (
            !(claimData.maxTotalSupply[_tokenId] == 0 ||
                claimData.totalSupply[_tokenId] + _quantity <= claimData.maxTotalSupply[_tokenId])
        ) {
            revert CrossedLimitMaxTotalSupply();
        }
        if (
            !(claimData.maxWalletClaimCount[_tokenId] == 0 ||
                claimData.walletClaimCount[_tokenId][_claimer] + _quantity <= claimData.maxWalletClaimCount[_tokenId])
        ) {
            revert CrossedLimitMaxWalletClaimCount();
        }

        (uint256 lastClaimTimestamp, uint256 nextValidClaimTimestamp) = getClaimTimestamp(
            claimData,
            _tokenId,
            _conditionId,
            _claimer
        );

        if (!(lastClaimTimestamp == 0 || block.timestamp >= nextValidClaimTimestamp)) revert InvalidTime();
    }

    /// @dev Collects and distributes the primary sale value of NFTs being claimed.
    function collectClaimPrice(
        DropERC1155DataTypes.ClaimData storage claimData,
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken,
        uint256 _tokenId,
        address msgSender,
        address primarySaleRecipient
    ) internal {
        if (_pricePerToken == 0) {
            return;
        }

        uint256 MAX_BPS = 10_000;

        uint256 totalPrice = _quantityToClaim * _pricePerToken;
        uint256 platformFees = (totalPrice * claimData.platformFeeBps) / MAX_BPS;

        if (_currency == CurrencyTransferLib.NATIVE_TOKEN && !(msg.value == totalPrice)) revert InvalidPrice();

        address recipient = claimData.saleRecipient[_tokenId] == address(0)
            ? primarySaleRecipient
            : claimData.saleRecipient[_tokenId];

        CurrencyTransferLib.transferCurrency(_currency, msgSender, claimData.platformFeeRecipient, platformFees);
        CurrencyTransferLib.transferCurrency(_currency, msgSender, recipient, totalPrice - platformFees);
    }

    /// @dev Book-keeping before the calling contract does the actual transfer and mint the relevant NFTs to claimer.
    function recordTransferClaimedTokens(
        DropERC1155DataTypes.ClaimData storage claimData,
        uint256 _conditionId,
        uint256 _tokenId,
        uint256 _quantityBeingClaimed,
        address msgSender
    ) public {
        // Update the supply minted under mint condition.
        claimData.claimCondition[_tokenId].phases[_conditionId].supplyClaimed += _quantityBeingClaimed;

        // if transfer claimed tokens is called when to != msg.sender, it'd use msg.sender's limits.
        // behavior would be similar to msg.sender mint for itself, then transfer to `to`.
        claimData.claimCondition[_tokenId].userClaims[_conditionId][msgSender].lastClaimTimestamp = block.timestamp;
        claimData.claimCondition[_tokenId].userClaims[_conditionId][msgSender].claimedBalance += _quantityBeingClaimed;
        claimData.walletClaimCount[_tokenId][msgSender] += _quantityBeingClaimed;
    }

    function verifyIssue(
        DropERC1155DataTypes.ClaimData storage claimData,
        uint256 _tokenId,
        uint256 _quantity
    ) external view {
        if (_quantity == 0) {
            revert InvalidQuantity();
        }
        if (
            claimData.maxTotalSupply[_tokenId] != 0 &&
            claimData.totalSupply[_tokenId] + _quantity > claimData.maxTotalSupply[_tokenId]
        ) {
            revert CrossedLimitMaxTotalSupply();
        }
    }

    /// @dev Expose the current active claim condition including claim limits
    function getActiveClaimConditions(DropERC1155DataTypes.ClaimData storage claimData, uint256 _tokenId)
        public
        view
        returns (
            IDropClaimConditionV0.ClaimCondition memory condition,
            uint256 conditionId,
            uint256 walletMaxClaimCount,
            uint256 remainingSupply
        )
    {
        conditionId = getActiveClaimConditionId(claimData, _tokenId);
        condition = claimData.claimCondition[_tokenId].phases[conditionId];
        walletMaxClaimCount = claimData.maxWalletClaimCount[_tokenId];

        if (claimData.maxTotalSupply[_tokenId] > 0) {
            remainingSupply = claimData.maxTotalSupply[_tokenId] - claimData.totalSupply[_tokenId];
        } else {
            remainingSupply = MAX_UINT256;
        }
    }

    /// @dev Returns the user specific limits related to the current active claim condition
    function getUserClaimConditions(
        DropERC1155DataTypes.ClaimData storage claimData,
        uint256 _tokenId,
        address _claimer
    )
        public
        view
        returns (
            uint256 conditionId,
            uint256 walletClaimedCount,
            uint256 lastClaimTimestamp,
            uint256 nextValidClaimTimestamp
        )
    {
        conditionId = getActiveClaimConditionId(claimData, _tokenId);
        (lastClaimTimestamp, nextValidClaimTimestamp) = getClaimTimestamp(claimData, _tokenId, conditionId, _claimer);
        walletClaimedCount = claimData.walletClaimCount[_tokenId][_claimer];
    }

    /// @dev Returns the current active claim condition ID.
    function getActiveClaimConditionId(DropERC1155DataTypes.ClaimData storage claimData, uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        IDropClaimConditionV0.ClaimConditionList storage conditionList = claimData.claimCondition[_tokenId];
        for (uint256 i = conditionList.currentStartId + conditionList.count; i > conditionList.currentStartId; i--) {
            if (block.timestamp >= conditionList.phases[i - 1].startTimestamp) {
                return i - 1;
            }
        }

        revert NoActiveMintCondition();
    }

    /// @dev Returns the timestamp for when a claimer is eligible for claiming NFTs again.
    function getClaimTimestamp(
        DropERC1155DataTypes.ClaimData storage claimData,
        uint256 _tokenId,
        uint256 _conditionId,
        address _claimer
    ) public view returns (uint256 lastClaimTimestamp, uint256 nextValidClaimTimestamp) {
        lastClaimTimestamp = claimData.claimCondition[_tokenId].userClaims[_conditionId][_claimer].lastClaimTimestamp;

        unchecked {
            nextValidClaimTimestamp =
                lastClaimTimestamp +
                claimData.claimCondition[_tokenId].phases[_conditionId].waitTimeInSecondsBetweenClaims;

            if (nextValidClaimTimestamp < lastClaimTimestamp) {
                nextValidClaimTimestamp = type(uint256).max;
            }
        }
    }
}