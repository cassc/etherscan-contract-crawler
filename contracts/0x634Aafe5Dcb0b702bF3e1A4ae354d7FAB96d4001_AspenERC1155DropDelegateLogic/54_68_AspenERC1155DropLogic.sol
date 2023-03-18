// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                           //
//                      _'                    AAA                                                                                            //
//                    !jz_                   A:::A                                                                                           //
//                 ;Lzzzz-                  A:::::A                                                                                          //
//              '1zzzzxzz'                 A:::::::A                                                                                         //
//            !xzzzzzzi~                  A:::::::::A             ssssssssss   ppppp   ppppppppp       eeeeeeeeeeee    nnnn  nnnnnnnn        //
//         ;izzzzzzj^`                   A:::::A:::::A          ss::::::::::s  p::::ppp:::::::::p    ee::::::::::::ee  n:::nn::::::::nn      //
//              `;^.`````               A:::::A A:::::A       ss:::::::::::::s p:::::::::::::::::p  e::::::eeeee:::::een::::::::::::::nn     //
//              -;;;;;;;-              A:::::A   A:::::A      s::::::ssss:::::spp::::::ppppp::::::pe::::::e     e:::::enn:::::::::::::::n    //
//           .;;;;;;;_                A:::::A     A:::::A      s:::::s  ssssss  p:::::p     p:::::pe:::::::eeeee::::::e  n:::::nnnn:::::n    //
//         ;;;;;;;;`                 A:::::AAAAAAAAA:::::A       s::::::s       p:::::p     p:::::pe:::::::::::::::::e   n::::n    n::::n    //
//      _;;;;;;;'                   A:::::::::::::::::::::A         s::::::s    p:::::p     p:::::pe::::::eeeeeeeeeee    n::::n    n::::n    //
//            ;{jjjjjjjjj          A:::::AAAAAAAAAAAAA:::::A  ssssss   s:::::s  p:::::p    p::::::pe:::::::e             n::::n    n::::n    //
//         `+IIIVVVVVVVVI`        A:::::A             A:::::A s:::::ssss::::::s p:::::ppppp:::::::pe::::::::e            n::::n    n::::n    //
//       ^sIVVVVVVVVVVVVI`       A:::::A               A:::::As::::::::::::::s  p::::::::::::::::p  e::::::::eeeeeeee    n::::n    n::::n    //
//    ~xIIIVVVVVVVVVVVVVI`      A:::::A                 A:::::As:::::::::::ss   p::::::::::::::pp    ee:::::::::::::e    n::::n    n::::n    //
//  -~~~;;;;;;;;;;;;;;;;;      AAAAAAA                   AAAAAAAsssssssssss     p::::::pppppppp        eeeeeeeeeeeeee    nnnnnn    nnnnnn    //
//                                                                              p:::::p                                                      //
//                                                                              p:::::p                                                      //
//                                                                             p:::::::p                                                     //
//                                                                             p:::::::p                                                     //
//                                                                             p:::::::p                                                     //
//                                                                             ppppppppp                                                     //
//                                                                                                                                           //
//  Website: https://aspenft.io/                                                                                                             //
//  Twitter: https://twitter.com/aspenft                                                                                                     //
//                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./lib/CurrencyTransferLib.sol";
import "./lib/MerkleProof.sol";
import "./types/DropERC1155DataTypes.sol";
import "../api/issuance/IDropClaimCondition.sol";
import "../api/royalties/IRoyalty.sol";
import "../api/errors/IDropErrors.sol";
import "../terms/types/TermsDataTypes.sol";

library AspenERC1155DropLogic {
    using StringsUpgradeable for uint256;
    using AspenERC1155DropLogic for DropERC1155DataTypes.ClaimData;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    uint256 public constant MAX_UINT256 = 2**256 - 1;
    /// @dev Max basis points (bps) in Aspen system.
    uint256 public constant MAX_BPS = 10_000;
    /// @dev Offset for token IDs.
    uint8 public constant TOKEN_INDEX_OFFSET = 1;
    /// @dev Only transfers to or from TRANSFER_ROLE holders are valid, when transfers are restricted.
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    struct InternalClaim {
        bool validMerkleProof;
        uint256 merkleProofIndex;
        uint256 activeConditionId;
        uint256 tokenIdToClaim;
        bytes32 phaseId;
    }

    function setClaimConditions(
        DropERC1155DataTypes.ClaimData storage claimData,
        uint256 _tokenId,
        IDropClaimConditionV1.ClaimCondition[] calldata _phases,
        bool _resetClaimEligibility
    ) external {
        if ((claimData.nextTokenIdToMint <= _tokenId)) revert IDropErrorsV0.InvalidTokenId(_tokenId);
        IDropClaimConditionV1.ClaimConditionList storage condition = claimData.claimCondition[_tokenId];
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
        bytes32[] memory phaseIds = new bytes32[](_phases.length);
        for (uint256 i = 0; i < _phases.length; i++) {
            if (!(i == 0 || lastConditionStartTimestamp < _phases[i].startTimestamp))
                revert IDropErrorsV0.InvalidTime();

            for (uint256 j = 0; j < phaseIds.length; j++) {
                if (phaseIds[j] == _phases[i].phaseId) revert IDropErrorsV0.InvalidPhaseId(_phases[i].phaseId);
                if (i == j) phaseIds[i] = _phases[i].phaseId;
            }

            uint256 supplyClaimedAlready = condition.phases[newStartIndex + i].supplyClaimed;

            if (_isOutOfLimits(_phases[i].maxClaimableSupply, supplyClaimedAlready))
                revert IDropErrorsV0.CrossedLimitMaxClaimableSupply();

            condition.phases[newStartIndex + i] = _phases[i];
            condition.phases[newStartIndex + i].supplyClaimed = supplyClaimedAlready;
            if (_phases[i].maxClaimableSupply == 0)
                condition.phases[newStartIndex + i].maxClaimableSupply = MAX_UINT256;

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
        address msgSender
    ) public returns (InternalClaim memory internalData) {
        if ((claimData.nextTokenIdToMint <= _tokenId)) revert IDropErrorsV0.InvalidTokenId(_tokenId);
        // Get the active claim condition index.
        internalData.phaseId = claimData.claimCondition[_tokenId].phases[internalData.activeConditionId].phaseId;

        (
            internalData.activeConditionId,
            internalData.validMerkleProof,
            internalData.merkleProofIndex
        ) = fullyVerifyClaim(
            claimData,
            msgSender,
            _tokenId,
            _quantity,
            _currency,
            _pricePerToken,
            _proofs,
            _proofMaxQuantityPerTransaction
        );

        // If there's a price, collect price.
        collectClaimPrice(claimData, _quantity, _currency, _pricePerToken, _tokenId, msgSender);

        // Book-keeping before the calling contract does the actual transfer and mint the relevant NFTs to claimer.
        recordTransferClaimedTokens(claimData, internalData.activeConditionId, _tokenId, _quantity, msgSender);
    }

    /// @dev We make allowlist checks (i.e. verifyClaimMerkleProof) before verifying the claim's general
    ///     validity (i.e. verifyClaim) because we give precedence to the check of allow list quantity
    ///     restriction over the check of the general claim condition's quantityLimitPerTransaction
    ///     restriction.
    function fullyVerifyClaim(
        DropERC1155DataTypes.ClaimData storage claimData,
        address _claimer,
        uint256 _tokenId,
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
        activeConditionId = getActiveClaimConditionId(claimData, _tokenId);
        // Verify inclusion in allowlist.
        (validMerkleProof, merkleProofIndex) = verifyClaimMerkleProof(
            claimData,
            activeConditionId,
            _claimer,
            _tokenId,
            _quantity,
            _proofs,
            _proofMaxQuantityPerTransaction
        );

        verifyClaim(claimData, activeConditionId, _claimer, _tokenId, _quantity, _currency, _pricePerToken);
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
        IDropClaimConditionV1.ClaimCondition memory currentClaimPhase = claimData.claimCondition[_tokenId].phases[
            _conditionId
        ];

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
                        claimData.claimCondition[_tokenId].userClaims[_conditionId][_claimer].claimedBalance)
            ) revert IDropErrorsV0.InvalidMaxQuantityProof();
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
        uint256 _pricePerToken
    ) public view {
        IDropClaimConditionV1.ClaimCondition memory currentClaimPhase = claimData.claimCondition[_tokenId].phases[
            _conditionId
        ];

        if (!(_currency == currentClaimPhase.currency && _pricePerToken == currentClaimPhase.pricePerToken)) {
            revert IDropErrorsV0.InvalidPrice();
        }
        verifyClaimQuantity(claimData, _conditionId, _claimer, _tokenId, _quantity);
        verifyClaimTimestamp(claimData, _conditionId, _claimer, _tokenId);
    }

    function verifyClaimQuantity(
        DropERC1155DataTypes.ClaimData storage claimData,
        uint256 _conditionId,
        address _claimer,
        uint256 _tokenId,
        uint256 _quantity
    ) public view {
        if (_quantity == 0) {
            revert IDropErrorsV0.InvalidQuantity();
        }

        IDropClaimConditionV1.ClaimCondition memory currentClaimPhase = claimData.claimCondition[_tokenId].phases[
            _conditionId
        ];

        if (!(_quantity > 0 && (_quantity <= currentClaimPhase.quantityLimitPerTransaction))) {
            revert IDropErrorsV0.CrossedLimitQuantityPerTransaction();
        }
        if (!(currentClaimPhase.supplyClaimed + _quantity <= currentClaimPhase.maxClaimableSupply)) {
            revert IDropErrorsV0.CrossedLimitMaxClaimableSupply();
        }
        if (_isOutOfLimits(claimData.maxTotalSupply[_tokenId], claimData.totalSupply[_tokenId] + _quantity)) {
            revert IDropErrorsV0.CrossedLimitMaxTotalSupply();
        }
        if (
            _isOutOfLimits(
                claimData.maxWalletClaimCount[_tokenId],
                claimData.walletClaimCount[_tokenId][_claimer] + _quantity
            )
        ) {
            revert IDropErrorsV0.CrossedLimitMaxWalletClaimCount();
        }
    }

    function verifyClaimTimestamp(
        DropERC1155DataTypes.ClaimData storage claimData,
        uint256 _conditionId,
        address _claimer,
        uint256 _tokenId
    ) public view {
        (uint256 lastClaimTimestamp, uint256 nextValidClaimTimestamp) = getClaimTimestamp(
            claimData,
            _tokenId,
            _conditionId,
            _claimer
        );

        if (!(lastClaimTimestamp == 0 || block.timestamp >= nextValidClaimTimestamp))
            revert IDropErrorsV0.InvalidTime();
    }

    function issueWithinPhase(
        DropERC1155DataTypes.ClaimData storage claimData,
        uint256 _tokenId,
        address _receiver,
        uint256 _quantity
    ) external {
        uint256 conditionId = getActiveClaimConditionId(claimData, _tokenId);
        verifyClaimQuantity(claimData, conditionId, _receiver, _tokenId, _quantity);
        recordTransferClaimedTokens(claimData, conditionId, _tokenId, _quantity, _receiver);
    }

    /// @dev Collects and distributes the primary sale value of NFTs being claimed.
    function collectClaimPrice(
        DropERC1155DataTypes.ClaimData storage claimData,
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken,
        uint256 _tokenId,
        address msgSender
    ) internal {
        if (_pricePerToken == 0) {
            return;
        }

        uint256 totalPrice = _quantityToClaim * _pricePerToken;
        uint256 platformFees = (totalPrice * claimData.platformFeeBps) / MAX_BPS;

        if (_currency == CurrencyTransferLib.NATIVE_TOKEN && !(msg.value == totalPrice))
            revert IDropErrorsV0.InvalidPaymentAmount();

        address recipient = claimData.saleRecipient[_tokenId] == address(0)
            ? claimData.primarySaleRecipient
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
            revert IDropErrorsV0.InvalidQuantity();
        }

        if (_isOutOfLimits(claimData.maxTotalSupply[_tokenId], claimData.totalSupply[_tokenId] + _quantity)) {
            revert IDropErrorsV0.CrossedLimitMaxTotalSupply();
        }
    }

    function setTokenURI(
        DropERC1155DataTypes.ClaimData storage claimData,
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

    function tokenURI(DropERC1155DataTypes.ClaimData storage claimData, uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        // Try to fetch possibly overridden tokenURI
        DropERC1155DataTypes.SequencedURI storage _tokenURI = claimData.tokenURIs[_tokenId];

        for (uint256 i = 0; i < claimData.baseURIIndices.length; i += 1) {
            if (_tokenId < claimData.baseURIIndices[i] + TOKEN_INDEX_OFFSET) {
                DropERC1155DataTypes.SequencedURI storage _baseURI = claimData.baseURI[
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
        DropERC1155DataTypes.ClaimData storage claimData,
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

    /// @dev Expose the current active claim condition including claim limits
    function getActiveClaimConditions(DropERC1155DataTypes.ClaimData storage claimData, uint256 _tokenId)
        public
        view
        returns (
            IDropClaimConditionV1.ClaimCondition memory condition,
            uint256 conditionId,
            uint256 walletMaxClaimCount,
            uint256 maxTotalSupply
        )
    {
        conditionId = getActiveClaimConditionId(claimData, _tokenId);
        condition = claimData.claimCondition[_tokenId].phases[conditionId];
        walletMaxClaimCount = claimData.maxWalletClaimCount[_tokenId];
        maxTotalSupply = claimData.maxTotalSupply[_tokenId];
    }

    /// @dev Returns basic info for claim data
    function getClaimData(DropERC1155DataTypes.ClaimData storage claimData, uint256 _tokenId)
        public
        view
        returns (
            uint256 nextTokenIdToMint,
            uint256 maxTotalSupply,
            uint256 maxWalletClaimCount
        )
    {
        nextTokenIdToMint = claimData.nextTokenIdToMint;
        maxTotalSupply = claimData.maxTotalSupply[_tokenId];
        maxWalletClaimCount = claimData.maxWalletClaimCount[_tokenId];
    }

    /// @dev Returns an array with all the claim conditions.
    function getClaimConditions(DropERC1155DataTypes.ClaimData storage claimData, uint256 _tokenId)
        public
        view
        returns (IDropClaimConditionV1.ClaimCondition[] memory conditions)
    {
        uint256 phaseCount = claimData.claimCondition[_tokenId].count;
        IDropClaimConditionV1.ClaimCondition[] memory _conditions = new IDropClaimConditionV1.ClaimCondition[](
            phaseCount
        );
        for (
            uint256 i = claimData.claimCondition[_tokenId].currentStartId;
            i < claimData.claimCondition[_tokenId].currentStartId + phaseCount;
            i++
        ) {
            _conditions[i - claimData.claimCondition[_tokenId].currentStartId] = claimData
                .claimCondition[_tokenId]
                .phases[i];
        }
        conditions = _conditions;
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
            uint256 walletClaimedCountInPhase,
            uint256 lastClaimTimestamp,
            uint256 nextValidClaimTimestamp
        )
    {
        conditionId = getActiveClaimConditionId(claimData, _tokenId);
        (lastClaimTimestamp, nextValidClaimTimestamp) = getClaimTimestamp(claimData, _tokenId, conditionId, _claimer);
        walletClaimedCount = claimData.walletClaimCount[_tokenId][_claimer];
        walletClaimedCountInPhase = claimData.claimCondition[_tokenId].userClaims[conditionId][_claimer].claimedBalance;
    }

    /// @dev Returns the current active claim condition ID.
    function getActiveClaimConditionId(DropERC1155DataTypes.ClaimData storage claimData, uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        IDropClaimConditionV1.ClaimConditionList storage conditionList = claimData.claimCondition[_tokenId];
        for (uint256 i = conditionList.currentStartId + conditionList.count; i > conditionList.currentStartId; i--) {
            if (block.timestamp >= conditionList.phases[i - 1].startTimestamp) {
                return i - 1;
            }
        }

        revert IDropErrorsV0.NoActiveMintCondition();
    }

    /// @dev Returns the claim condition at the given uid.
    function getClaimConditionById(
        DropERC1155DataTypes.ClaimData storage claimData,
        uint256 _tokenId,
        uint256 _conditionId
    ) external view returns (IDropClaimConditionV1.ClaimCondition memory condition) {
        condition = claimData.claimCondition[_tokenId].phases[_conditionId];
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

    /// @dev Returns the royalty recipient and bps for a particular token Id.
    function getRoyaltyInfoForToken(DropERC1155DataTypes.ClaimData storage claimData, uint256 _tokenId)
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
        DropERC1155DataTypes.ClaimData storage claimData,
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount) {
        (address recipient, uint256 bps) = getRoyaltyInfoForToken(claimData, tokenId);
        receiver = recipient;
        royaltyAmount = (salePrice * bps) / MAX_BPS;
    }

    function setDefaultRoyaltyInfo(
        DropERC1155DataTypes.ClaimData storage claimData,
        address _royaltyRecipient,
        uint256 _royaltyBps
    ) external {
        if (!(_royaltyBps <= MAX_BPS)) revert IDropErrorsV0.MaxBps();

        claimData.royaltyRecipient = _royaltyRecipient;
        claimData.royaltyBps = uint16(_royaltyBps);
    }

    function setRoyaltyInfoForToken(
        DropERC1155DataTypes.ClaimData storage claimData,
        uint256 _tokenId,
        address _recipient,
        uint256 _bps
    ) external {
        if (!(_bps <= MAX_BPS)) revert IDropErrorsV0.MaxBps();

        claimData.royaltyInfoForToken[_tokenId] = IRoyaltyV0.RoyaltyInfo({recipient: _recipient, bps: _bps});
    }

    /// @dev See {ERC1155-_beforeTokenTransfer}.
    function beforeTokenTransfer(
        DropERC1155DataTypes.ClaimData storage claimData,
        TermsDataTypes.Terms storage termsData,
        IAccessControlUpgradeable accessControl,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external {
        // if transfer is restricted on the contract, we still want to allow burning and minting
        if (!accessControl.hasRole(TRANSFER_ROLE, address(0)) && from != address(0) && to != address(0)) {
            if (!(accessControl.hasRole(TRANSFER_ROLE, from) || accessControl.hasRole(TRANSFER_ROLE, to)))
                revert IDropErrorsV0.InvalidPermission();
        }

        if (to != address(this)) {
            if (termsData.termsActivated) {
                if (!termsData.termsAccepted[to] || termsData.termsVersion != termsData.acceptedVersion[to])
                    revert IDropErrorsV0.TermsNotAccepted(to, termsData.termsURI, termsData.termsVersion);
            }
        }

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                claimData.totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                claimData.totalSupply[ids[i]] -= amounts[i];
            }
        }
    }

    /// @dev Checks if a value is outside of a limit.
    /// @param _limit The limit to check against.
    /// @param _value The value to check.
    /// @return True if the value is there is a limit and it's outside of that limit.
    function _isOutOfLimits(uint256 _limit, uint256 _value) internal pure returns (bool) {
        return _limit != 0 && !(_value <= _limit);
    }
}