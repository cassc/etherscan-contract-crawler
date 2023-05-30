// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import "./lib/CurrencyTransferLib.sol";
import "./lib/MerkleProof.sol";
import "./types/DropERC721DataTypes.sol";
import "./../api/standard/IERC1155.sol";
import "./../api/royalties/IRoyalty.sol";
import "../api/errors/IDropErrors.sol";

library AspenERC721DropLogic {
    using StringsUpgradeable for uint256;
    using AspenERC721DropLogic for DropERC721DataTypes.ClaimData;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    uint256 private constant MAX_UINT256 = 2**256 - 1;
    /// @dev Max basis points (bps) in Aspen system.
    uint256 public constant MAX_BPS = 10_000;
    /// @dev Offset for token IDs.
    uint8 public constant TOKEN_INDEX_OFFSET = 1;

    struct InternalClaim {
        bool validMerkleProof;
        uint256 merkleProofIndex;
        uint256 activeConditionId;
        uint256 tokenIdToClaim;
        bytes32 phaseId;
    }

    function setClaimConditions(
        DropERC721DataTypes.ClaimData storage claimData,
        IDropClaimConditionV1.ClaimCondition[] calldata _phases,
        bool _resetClaimEligibility
    ) public {
        uint256 existingStartIndex = claimData.claimCondition.currentStartId;
        uint256 existingPhaseCount = claimData.claimCondition.count;

        uint256 newStartIndex = existingStartIndex;
        if (_resetClaimEligibility) {
            newStartIndex = existingStartIndex + existingPhaseCount;
        }

        claimData.claimCondition.count = _phases.length;
        claimData.claimCondition.currentStartId = newStartIndex;

        uint256 lastConditionStartTimestamp;
        bytes32[] memory phaseIds = new bytes32[](_phases.length);
        for (uint256 i = 0; i < _phases.length; i++) {
            if (!(i == 0 || lastConditionStartTimestamp < _phases[i].startTimestamp))
                revert IDropErrorsV0.InvalidTimetamp();

            for (uint256 j = 0; j < phaseIds.length; j++) {
                if (phaseIds[j] == _phases[i].phaseId) revert IDropErrorsV0.InvalidPhaseId(_phases[i].phaseId);
                if (i == j) phaseIds[i] = _phases[i].phaseId;
            }

            uint256 supplyClaimedAlready = claimData.claimCondition.phases[newStartIndex + i].supplyClaimed;

            if (_isOutOfLimits(_phases[i].maxClaimableSupply, supplyClaimedAlready))
                revert IDropErrorsV0.CrossedLimitMaxClaimableSupply();

            claimData.claimCondition.phases[newStartIndex + i] = _phases[i];
            claimData.claimCondition.phases[newStartIndex + i].supplyClaimed = supplyClaimedAlready;
            if (_phases[i].maxClaimableSupply == 0)
                claimData.claimCondition.phases[newStartIndex + i].maxClaimableSupply = MAX_UINT256;

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
            }
        } else {
            if (existingPhaseCount > _phases.length) {
                for (uint256 i = _phases.length; i < existingPhaseCount; i++) {
                    delete claimData.claimCondition.phases[newStartIndex + i];
                }
            }
        }
    }

    function executeClaim(
        DropERC721DataTypes.ClaimData storage claimData,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bytes32[] calldata _proofs,
        uint256 _proofMaxQuantityPerTransaction,
        address msgSender
    ) public returns (uint256[] memory tokens, InternalClaim memory internalData) {
        internalData.tokenIdToClaim = claimData.nextTokenIdToClaim;
        internalData.phaseId = claimData.claimCondition.phases[internalData.activeConditionId].phaseId;

        (
            internalData.activeConditionId,
            internalData.validMerkleProof,
            internalData.merkleProofIndex
        ) = fullyVerifyClaim(
            claimData,
            msgSender,
            _quantity,
            _currency,
            _pricePerToken,
            _proofs,
            _proofMaxQuantityPerTransaction
        );

        // If there's a price, collect price.
        claimData.collectClaimPrice(_quantity, _currency, _pricePerToken, msgSender);

        // Book-keeping before the calling contract does the actual transfer and mint the relevant NFTs to claimer.
        tokens = recordTransferClaimedTokens(claimData, internalData.activeConditionId, _quantity, msgSender);
    }

    /// @dev We make allowlist checks (i.e. verifyClaimMerkleProof) before verifying the claim's general
    ///     validity (i.e. verifyClaim) because we give precedence to the check of allow list quantity
    ///     restriction over the check of the general claim condition's quantityLimitPerTransaction
    ///     restriction.
    function fullyVerifyClaim(
        DropERC721DataTypes.ClaimData storage claimData,
        address _claimer,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bytes32[] calldata _proofs,
        uint256 _proofMaxQuantityPerTransaction
    )
        public
        view
        returns (
            uint256 activeConditionId,
            bool validMerkleProof,
            uint256 merkleProofIndex
        )
    {
        activeConditionId = getActiveClaimConditionId(claimData);
        // Verify inclusion in allowlist.
        (validMerkleProof, merkleProofIndex) = verifyClaimMerkleProof(
            claimData,
            activeConditionId,
            _claimer,
            _quantity,
            _proofs,
            _proofMaxQuantityPerTransaction
        );

        verifyClaim(claimData, activeConditionId, _claimer, _quantity, _currency, _pricePerToken);
    }

    function verifyClaimMerkleProof(
        DropERC721DataTypes.ClaimData storage claimData,
        uint256 _conditionId,
        address _claimer,
        uint256 _quantity,
        bytes32[] calldata _proofs,
        uint256 _proofMaxQuantityPerTransaction
    ) public view returns (bool validMerkleProof, uint256 merkleProofIndex) {
        IDropClaimConditionV1.ClaimCondition memory currentClaimPhase = claimData.claimCondition.phases[_conditionId];

        if (currentClaimPhase.merkleRoot != bytes32(0)) {
            (validMerkleProof, merkleProofIndex) = MerkleProof.verify(
                _proofs,
                currentClaimPhase.merkleRoot,
                keccak256(abi.encodePacked(_claimer, _proofMaxQuantityPerTransaction))
            );

            if (!validMerkleProof) revert IDropErrorsV0.InvalidMerkleProof();
            if (
                !(_proofMaxQuantityPerTransaction == 0 ||
                    _quantity <=
                    _proofMaxQuantityPerTransaction -
                        claimData.claimCondition.userClaims[_conditionId][_claimer].claimedBalance)
            ) revert IDropErrorsV0.InvalidMaxQuantityProof();
        }
    }

    /// @dev Checks a request to claim NFTs against the active claim condition's criteria.
    function verifyClaim(
        DropERC721DataTypes.ClaimData storage claimData,
        uint256 _conditionId,
        address _claimer,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken
    ) public view {
        IDropClaimConditionV1.ClaimCondition memory currentClaimPhase = claimData.claimCondition.phases[_conditionId];

        if (!(_currency == currentClaimPhase.currency && _pricePerToken == currentClaimPhase.pricePerToken)) {
            revert IDropErrorsV0.InvalidPrice();
        }
        verifyClaimQuantity(claimData, _conditionId, _claimer, _quantity);
        verifyClaimTimestamp(claimData, _conditionId, _claimer);
    }

    function verifyClaimQuantity(
        DropERC721DataTypes.ClaimData storage claimData,
        uint256 _conditionId,
        address _claimer,
        uint256 _quantity
    ) public view {
        IDropClaimConditionV1.ClaimCondition memory currentClaimPhase = claimData.claimCondition.phases[_conditionId];
        if (_quantity == 0) {
            revert IDropErrorsV0.InvalidQuantity();
        }
        // If we're checking for an allowlist quantity restriction, ignore the general quantity restriction.
        if (!(_quantity > 0 && _quantity <= currentClaimPhase.quantityLimitPerTransaction)) {
            revert IDropErrorsV0.CrossedLimitQuantityPerTransaction();
        }
        if (!(currentClaimPhase.supplyClaimed + _quantity <= currentClaimPhase.maxClaimableSupply)) {
            revert IDropErrorsV0.CrossedLimitMaxClaimableSupply();
        }
        // nextTokenIdToMint is the supremum of all tokens currently lazy minted so this is just checking we are no
        // trying to claim a token that has not yet been lazyminted (therefore has no URI)
        if (!(claimData.nextTokenIdToClaim + _quantity <= claimData.nextTokenIdToMint)) {
            revert IDropErrorsV0.CrossedLimitLazyMintedTokens();
        }
        if (_isOutOfLimits(claimData.maxTotalSupply, claimData.nextTokenIdToClaim - TOKEN_INDEX_OFFSET + _quantity)) {
            revert IDropErrorsV0.CrossedLimitMaxTotalSupply();
        }
        if (_isOutOfLimits(claimData.maxWalletClaimCount, claimData.walletClaimCount[_claimer] + _quantity)) {
            revert IDropErrorsV0.CrossedLimitMaxWalletClaimCount();
        }
    }

    function verifyClaimTimestamp(
        DropERC721DataTypes.ClaimData storage claimData,
        uint256 _conditionId,
        address _claimer
    ) public view {
        (uint256 lastClaimTimestamp, uint256 nextValidClaimTimestamp) = getClaimTimestamp(
            claimData,
            _conditionId,
            _claimer
        );
        if (!(lastClaimTimestamp == 0 || block.timestamp >= nextValidClaimTimestamp))
            revert IDropErrorsV0.InvalidTime();
    }

    function issueWithinPhase(
        DropERC721DataTypes.ClaimData storage claimData,
        address _receiver,
        uint256 _quantity
    ) public returns (uint256[] memory tokenIds) {
        uint256 currentClaimId = getActiveClaimConditionId(claimData);
        verifyClaimQuantity(claimData, currentClaimId, _receiver, _quantity);
        tokenIds = recordTransferClaimedTokens(claimData, currentClaimId, _quantity, _receiver);
    }

    function transferTokens(DropERC721DataTypes.ClaimData storage claimData, uint256 _quantityBeingClaimed)
        public
        returns (uint256[] memory tokenIds)
    {
        uint256 tokenIdToClaim = claimData.nextTokenIdToClaim;

        tokenIds = new uint256[](_quantityBeingClaimed);

        for (uint256 i = 0; i < _quantityBeingClaimed; i += 1) {
            tokenIds[i] = tokenIdToClaim;
            tokenIdToClaim += 1;
        }

        claimData.nextTokenIdToClaim = tokenIdToClaim;
    }

    /// @dev Collects and distributes the primary sale value of NFTs being claimed.
    function collectClaimPrice(
        DropERC721DataTypes.ClaimData storage claimData,
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken,
        address msgSender
    ) internal {
        if (_pricePerToken == 0) {
            return;
        }

        uint256 totalPrice = _quantityToClaim * _pricePerToken;
        uint256 platformFees = (totalPrice * claimData.platformFeeBps) / MAX_BPS;

        if (_currency == CurrencyTransferLib.NATIVE_TOKEN && !(msg.value == totalPrice))
            revert IDropErrorsV0.InvalidPaymentAmount();

        CurrencyTransferLib.transferCurrency(_currency, msgSender, claimData.platformFeeRecipient, platformFees);
        CurrencyTransferLib.transferCurrency(
            _currency,
            msgSender,
            claimData.primarySaleRecipient,
            totalPrice - platformFees
        );
    }

    /// @dev Book-keeping before the calling contract does the actual transfer and mint the relevant NFTs to claimer.
    function recordTransferClaimedTokens(
        DropERC721DataTypes.ClaimData storage claimData,
        uint256 _conditionId,
        uint256 _quantityBeingClaimed,
        address msgSender
    ) public returns (uint256[] memory tokenIds) {
        // Update the supply minted under mint condition.
        claimData.claimCondition.phases[_conditionId].supplyClaimed += _quantityBeingClaimed;

        // if transfer claimed tokens is called when `to != msg.sender`, it'd use msg.sender's limits.
        // behavior would be similar to `msg.sender` mint for itself, then transfer to `_to`.
        claimData.claimCondition.userClaims[_conditionId][msgSender].lastClaimTimestamp = block.timestamp;
        claimData.claimCondition.userClaims[_conditionId][msgSender].claimedBalance += _quantityBeingClaimed;
        claimData.walletClaimCount[msgSender] += _quantityBeingClaimed;

        tokenIds = transferTokens(claimData, _quantityBeingClaimed);
    }

    function verifyIssue(DropERC721DataTypes.ClaimData storage claimData, uint256 _quantity)
        public
        returns (uint256[] memory tokenIds)
    {
        if (_quantity == 0) {
            revert IDropErrorsV0.InvalidQuantity();
        }
        uint256 nextNextTokenIdToMint = claimData.nextTokenIdToClaim + _quantity;
        if (nextNextTokenIdToMint > claimData.nextTokenIdToMint) {
            revert IDropErrorsV0.CrossedLimitLazyMintedTokens();
        }
        if (claimData.maxTotalSupply != 0 && nextNextTokenIdToMint - TOKEN_INDEX_OFFSET > claimData.maxTotalSupply) {
            revert IDropErrorsV0.CrossedLimitMaxTotalSupply();
        }
        tokenIds = transferTokens(claimData, _quantity);
    }

    function setTokenURI(
        DropERC721DataTypes.ClaimData storage claimData,
        uint256 _tokenId,
        string memory _tokenURI,
        bool _isPermanent
    ) public {
        // Interpret empty string as unsetting tokenURI
        if (bytes(_tokenURI).length == 0) {
            claimData.tokenURIs[_tokenId].sequenceNumber = 0;
            return;
        }
        // Bump the sequence first
        claimData.uriSequenceCounter.increment();
        claimData.tokenURIs[_tokenId].uri = _tokenURI;
        claimData.tokenURIs[_tokenId].sequenceNumber = claimData.uriSequenceCounter.current();
        claimData.tokenURIs[_tokenId].isPermanent = _isPermanent;
    }

    function tokenURI(DropERC721DataTypes.ClaimData storage claimData, uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        // Try to fetch possibly overridden tokenURI
        DropERC721DataTypes.SequencedURI storage _tokenURI = claimData.tokenURIs[_tokenId];

        for (uint256 i = 0; i < claimData.baseURIIndices.length; i += 1) {
            if (_tokenId < claimData.baseURIIndices[i] + TOKEN_INDEX_OFFSET) {
                DropERC721DataTypes.SequencedURI storage _baseURI = claimData.baseURI[
                    claimData.baseURIIndices[i] + TOKEN_INDEX_OFFSET
                ];
                if (_tokenURI.sequenceNumber > _baseURI.sequenceNumber || _tokenURI.isPermanent) {
                    // If the specifically set tokenURI is fresher than the baseURI OR
                    // if the tokenURI is permanet then return that (it is in-force)
                    return _tokenURI.uri;
                }
                // Otherwise either there is no override (sequenceNumber == 0) or the baseURI is fresher, so return the
                // baseURI-derived tokenURI
                return string(abi.encodePacked(_baseURI.uri, _tokenId.toString()));
            }
        }
        return "";
    }

    function lazyMint(
        DropERC721DataTypes.ClaimData storage claimData,
        uint256 _amount,
        string calldata _baseURIForTokens
    ) public returns (uint256 startId, uint256 baseURIIndex) {
        if (_amount == 0) revert IDropErrorsV0.InvalidNoOfTokenIds();
        claimData.uriSequenceCounter.increment();
        startId = claimData.nextTokenIdToMint;
        baseURIIndex = startId + _amount;

        claimData.nextTokenIdToMint = baseURIIndex;
        claimData.baseURI[baseURIIndex].uri = _baseURIForTokens;
        claimData.baseURI[baseURIIndex].sequenceNumber = claimData.uriSequenceCounter.current();
        claimData.baseURI[baseURIIndex].amountOfTokens = _amount;
        claimData.baseURIIndices.push(baseURIIndex - TOKEN_INDEX_OFFSET);
    }

    /// @dev Returns basic info for claim data
    function getClaimData(DropERC721DataTypes.ClaimData storage claimData)
        public
        view
        returns (
            uint256 nextTokenIdToMint,
            uint256 maxTotalSupply,
            uint256 maxWalletClaimCount
        )
    {
        nextTokenIdToMint = claimData.nextTokenIdToMint;
        maxTotalSupply = claimData.maxTotalSupply;
        maxWalletClaimCount = claimData.maxWalletClaimCount;
    }

    /// @dev Returns an array with all the claim conditions.
    function getClaimConditions(DropERC721DataTypes.ClaimData storage claimData)
        public
        view
        returns (IDropClaimConditionV1.ClaimCondition[] memory conditions)
    {
        uint256 phaseCount = claimData.claimCondition.count;
        IDropClaimConditionV1.ClaimCondition[] memory _conditions = new IDropClaimConditionV1.ClaimCondition[](
            phaseCount
        );
        for (
            uint256 i = claimData.claimCondition.currentStartId;
            i < claimData.claimCondition.currentStartId + phaseCount;
            i++
        ) {
            _conditions[i - claimData.claimCondition.currentStartId] = claimData.claimCondition.phases[i];
        }
        conditions = _conditions;
    }

    /// @dev Returns the claim condition at the given uid.
    function getClaimConditionById(DropERC721DataTypes.ClaimData storage claimData, uint256 _conditionId)
        external
        view
        returns (IDropClaimConditionV1.ClaimCondition memory condition)
    {
        condition = claimData.claimCondition.phases[_conditionId];
    }

    /// @dev Returns the user specific limits related to the current active claim condition
    function getUserClaimConditions(DropERC721DataTypes.ClaimData storage claimData, address _claimer)
        public
        view
        returns (
            uint256 conditionId,
            uint256 walletClaimedCount,
            uint256 walletClaimedCountInPhase,
            uint256 lastClaimTimestamp,
            uint256 nextValidClaimTimestamp
        )
    {
        conditionId = getActiveClaimConditionId(claimData);
        (lastClaimTimestamp, nextValidClaimTimestamp) = getClaimTimestamp(claimData, conditionId, _claimer);
        walletClaimedCount = claimData.walletClaimCount[_claimer];
        walletClaimedCountInPhase = claimData.claimCondition.userClaims[conditionId][_claimer].claimedBalance;
    }

    function getActiveClaimConditions(DropERC721DataTypes.ClaimData storage claimData)
        public
        view
        returns (
            IDropClaimConditionV1.ClaimCondition memory condition,
            uint256 conditionId,
            uint256 walletMaxClaimCount,
            uint256 maxTotalSupply
        )
    {
        conditionId = getActiveClaimConditionId(claimData);
        condition = claimData.claimCondition.phases[conditionId];
        walletMaxClaimCount = claimData.maxWalletClaimCount;
        maxTotalSupply = claimData.maxTotalSupply;
    }

    /// @dev Returns the current active claim condition ID.
    function getActiveClaimConditionId(DropERC721DataTypes.ClaimData storage claimData) public view returns (uint256) {
        for (
            uint256 i = claimData.claimCondition.currentStartId + claimData.claimCondition.count;
            i > claimData.claimCondition.currentStartId;
            i--
        ) {
            if (block.timestamp >= claimData.claimCondition.phases[i - 1].startTimestamp) {
                return i - 1;
            }
        }

        revert IDropErrorsV0.NoActiveMintCondition();
    }

    /// @dev Returns the timestamp for when a claimer is eligible for claiming NFTs again.
    function getClaimTimestamp(
        DropERC721DataTypes.ClaimData storage claimData,
        uint256 _conditionId,
        address _claimer
    ) public view returns (uint256 lastClaimTimestamp, uint256 nextValidClaimTimestamp) {
        lastClaimTimestamp = claimData.claimCondition.userClaims[_conditionId][_claimer].lastClaimTimestamp;

        unchecked {
            nextValidClaimTimestamp =
                lastClaimTimestamp +
                claimData.claimCondition.phases[_conditionId].waitTimeInSecondsBetweenClaims;

            if (nextValidClaimTimestamp < lastClaimTimestamp) {
                nextValidClaimTimestamp = type(uint256).max;
            }
        }
    }

    /// @dev Returns the royalty recipient and bps for a particular token Id.
    function getRoyaltyInfoForToken(DropERC721DataTypes.ClaimData storage claimData, uint256 _tokenId)
        public
        view
        returns (address, uint16)
    {
        IRoyaltyV0.RoyaltyInfo memory royaltyForToken = claimData.royaltyInfoForToken[_tokenId];

        return
            royaltyForToken.recipient == address(0)
                ? (claimData.royaltyRecipient, uint16(claimData.royaltyBps))
                : (royaltyForToken.recipient, uint16(royaltyForToken.bps));
    }

    /// @dev See ERC-2891 - Returns the royalty recipient and amount, given a tokenId and sale price.
    function royaltyInfo(
        DropERC721DataTypes.ClaimData storage claimData,
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount) {
        (address recipient, uint256 bps) = getRoyaltyInfoForToken(claimData, tokenId);
        receiver = recipient;
        royaltyAmount = (salePrice * bps) / MAX_BPS;
    }

    function setDefaultRoyaltyInfo(
        DropERC721DataTypes.ClaimData storage claimData,
        address _royaltyRecipient,
        uint256 _royaltyBps
    ) external {
        if (!(_royaltyBps <= MAX_BPS)) revert IDropErrorsV0.MaxBps();
        claimData.royaltyRecipient = _royaltyRecipient;
        claimData.royaltyBps = uint16(_royaltyBps);
    }

    function setRoyaltyInfoForToken(
        DropERC721DataTypes.ClaimData storage claimData,
        uint256 _tokenId,
        address _recipient,
        uint256 _bps
    ) external {
        if (!(_bps <= MAX_BPS)) revert IDropErrorsV0.MaxBps();
        claimData.royaltyInfoForToken[_tokenId] = IRoyaltyV0.RoyaltyInfo({recipient: _recipient, bps: _bps});
    }

    /// @dev Checks if a value is outside of a limit.
    /// @param _limit The limit to check against.
    /// @param _value The value to check.
    /// @return True if the value is there is a limit and it's outside of that limit.
    function _isOutOfLimits(uint256 _limit, uint256 _value) internal pure returns (bool) {
        return _limit != 0 && !(_value <= _limit);
    }
}