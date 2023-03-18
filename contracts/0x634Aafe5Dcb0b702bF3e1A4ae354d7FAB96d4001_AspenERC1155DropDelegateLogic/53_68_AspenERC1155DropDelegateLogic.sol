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

import "./AspenERC1155DropStorage.sol";
import "./../api/issuance/IDropClaimCondition.sol";
import "../generated/impl/BaseAspenERC1155DropV2.sol";

contract AspenERC1155DropDelegateLogic is
    IDropClaimConditionV1,
    AspenERC1155DropStorage,
    IDelegateBaseAspenERC1155DropV2
{
    /// ================================
    /// =========== Libraries ==========
    /// ================================
    using StringsUpgradeable for uint256;
    using TermsLogic for TermsDataTypes.Terms;
    using AspenERC1155DropLogic for DropERC1155DataTypes.ClaimData;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    constructor() {}

    function initialize() external initializer {}

    /// @dev See ERC 165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return AspenERC1155DropStorage.supportsInterface(interfaceId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function setTokenURI(uint256 _tokenId, string memory _tokenURI)
        external
        virtual
        override
        isValidTokenId(_tokenId)
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setTokenURI(_tokenId, _tokenURI, false);
    }

    function setPermantentTokenURI(uint256 _tokenId, string memory _tokenURI)
        external
        virtual
        override
        isValidTokenId(_tokenId)
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setTokenURI(_tokenId, _tokenURI, true);
        emit PermanentURI(_tokenURI, _tokenId);
    }

    function _setTokenURI(
        uint256 _tokenId,
        string memory _tokenURI,
        bool isPermanent
    ) internal {
        if (claimData.totalSupply[_tokenId] <= 0) revert IDropErrorsV0.InvalidTokenId(_tokenId);
        if (claimData.tokenURIs[_tokenId].isPermanent) revert IDropErrorsV0.FrozenTokenMetadata(_tokenId);
        AspenERC1155DropLogic.setTokenURI(claimData, _tokenId, _tokenURI, isPermanent);
        emit TokenURIUpdated(_tokenId, _msgSender(), _tokenURI);
        emit URI(_tokenURI, _tokenId);
        emit MetadataUpdate(_tokenId);
    }

    /// ======================================
    /// =========== Minting logic ============
    /// ======================================
    /// @dev Lets an account with `MINTER_ROLE` lazy mint 'n' NFTs.
    ///        The URIs for each token is the provided `_baseURIForTokens` + `{tokenId}`.
    function lazyMint(uint256 _noOfTokenIds, string calldata _baseURIForTokens)
        external
        override
        onlyRole(MINTER_ROLE)
    {
        (uint256 startId, uint256 baseURIIndex) = AspenERC1155DropLogic.lazyMint(
            claimData,
            _noOfTokenIds,
            _baseURIForTokens
        );
        emit TokensLazyMinted(startId, baseURIIndex - TOKEN_INDEX_OFFSET, _baseURIForTokens);
    }

    /// ======================================
    /// ============= Issue logic ============
    /// ======================================
    /// @dev Lets an account claim a given quantity of NFTs, of a single tokenId.
    function issue(
        address _receiver,
        uint256 _tokenId,
        uint256 _quantity
    ) external override nonReentrant isValidTokenId(_tokenId) onlyRole(ISSUER_ROLE) {
        AspenERC1155DropLogic.verifyIssue(claimData, _tokenId, _quantity);

        _mint(_receiver, _tokenId, _quantity, "");

        emit TokensIssued(_tokenId, _msgSender(), _receiver, _quantity);
    }

    /// @dev Lets an account claim a given quantity of NFTs, of a single tokenId, with respecting the
    ///     claim conditions on quantity.
    function issueWithinPhase(
        address _receiver,
        uint256 _tokenId,
        uint256 _quantity
    ) external override nonReentrant isValidTokenId(_tokenId) onlyRole(ISSUER_ROLE) {
        AspenERC1155DropLogic.issueWithinPhase(claimData, _tokenId, _receiver, _quantity);

        _mint(_receiver, _tokenId, _quantity, "");

        emit TokensIssued(_tokenId, _msgSender(), _receiver, _quantity);
    }

    /// ======================================
    /// ============= Admin logic ============
    /// ======================================
    /// @dev Lets a contract admin (account with `DEFAULT_ADMIN_ROLE`) set claim conditions, for a tokenId.
    function setClaimConditions(
        uint256 _tokenId,
        ClaimCondition[] calldata _phases,
        bool _resetClaimEligibility
    ) external override isValidTokenId(_tokenId) onlyRole(DEFAULT_ADMIN_ROLE) {
        AspenERC1155DropLogic.setClaimConditions(claimData, _tokenId, _phases, _resetClaimEligibility);
        emit ClaimConditionsUpdated(_tokenId, _phases);
    }

    /// @dev Lets a contract admin set a new owner for the contract.
    function setOwner(address _newOwner) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        address _prevOwner = _owner;
        _owner = _newOwner;
        emit OwnershipTransferred(_prevOwner, _newOwner);
    }

    /// @dev Lets a contract admin set the token name and symbol.
    function setTokenNameAndSymbol(string calldata _name, string calldata _symbol)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        __name = _name;
        __symbol = _symbol;

        emit TokenNameAndSymbolUpdated(_msgSender(), __name, __symbol);
    }

    /// @dev Lets a contract admin set the recipient for all primary sales.
    function setPrimarySaleRecipient(address _saleRecipient) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        claimData.primarySaleRecipient = _saleRecipient;
        emit PrimarySaleRecipientUpdated(_saleRecipient);
    }

    /// @dev Lets a contract admin set the recipient for all primary sales.
    function setSaleRecipientForToken(uint256 _tokenId, address _saleRecipient)
        external
        override
        isValidTokenId(_tokenId)
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        claimData.saleRecipient[_tokenId] = _saleRecipient;
        emit SaleRecipientForTokenUpdated(_tokenId, _saleRecipient);
    }

    /// @dev Lets a contract admin update the default royalty recipient and bps.
    function setDefaultRoyaltyInfo(address _royaltyRecipient, uint256 _royaltyBps)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        AspenERC1155DropLogic.setDefaultRoyaltyInfo(claimData, _royaltyRecipient, _royaltyBps);
        emit DefaultRoyalty(_royaltyRecipient, _royaltyBps);
    }

    /// @dev Lets a contract admin set the royalty recipient and bps for a particular token Id.
    function setRoyaltyInfoForToken(
        uint256 _tokenId,
        address _recipient,
        uint256 _bps
    ) external override isValidTokenId(_tokenId) onlyRole(DEFAULT_ADMIN_ROLE) {
        AspenERC1155DropLogic.setRoyaltyInfoForToken(claimData, _tokenId, _recipient, _bps);
        emit RoyaltyForToken(_tokenId, _recipient, _bps);
    }

    /// @dev Lets a contract admin set a claim count for a wallet.
    function setWalletClaimCount(
        uint256 _tokenId,
        address _claimer,
        uint256 _count
    ) external override isValidTokenId(_tokenId) onlyRole(DEFAULT_ADMIN_ROLE) {
        claimData.walletClaimCount[_tokenId][_claimer] = _count;
        emit WalletClaimCountUpdated(_tokenId, _claimer, _count);
    }

    /// @dev Lets a contract admin set a maximum number of NFTs of a tokenId that can be claimed by any wallet.
    function setMaxWalletClaimCount(uint256 _tokenId, uint256 _count)
        external
        override
        isValidTokenId(_tokenId)
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        claimData.maxWalletClaimCount[_tokenId] = _count;
        emit MaxWalletClaimCountUpdated(_tokenId, _count);
    }

    /// @dev Lets a module admin set a max total supply for token.
    function setMaxTotalSupply(uint256 _tokenId, uint256 _maxTotalSupply)
        external
        isValidTokenId(_tokenId)
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (_maxTotalSupply != 0 && claimData.totalSupply[_tokenId] > _maxTotalSupply) {
            revert IDropErrorsV0.CrossedLimitMaxTotalSupply();
        }
        claimData.maxTotalSupply[_tokenId] = _maxTotalSupply;
        emit MaxTotalSupplyUpdated(_tokenId, _maxTotalSupply);
    }

    /// @dev Lets a contract admin set the URI for contract-level metadata.
    function setContractURI(string calldata _uri) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _contractUri = _uri;
        emit ContractURIUpdated(_msgSender(), _uri);
    }

    /// @dev Lets an account with `MINTER_ROLE` update base URI.
    function updateBaseURI(uint256 baseURIIndex, string calldata _baseURIForTokens)
        external
        override
        onlyRole(MINTER_ROLE)
    {
        if (bytes(claimData.baseURI[baseURIIndex + TOKEN_INDEX_OFFSET].uri).length == 0)
            revert IDropErrorsV0.BaseURIEmpty();

        claimData.uriSequenceCounter.increment();
        claimData.baseURI[baseURIIndex + TOKEN_INDEX_OFFSET].uri = _baseURIForTokens;
        claimData.baseURI[baseURIIndex + TOKEN_INDEX_OFFSET].sequenceNumber = claimData.uriSequenceCounter.current();

        emit BaseURIUpdated(baseURIIndex, _baseURIForTokens);
        emit BatchMetadataUpdate(
            baseURIIndex + TOKEN_INDEX_OFFSET - claimData.baseURI[baseURIIndex + TOKEN_INDEX_OFFSET].amountOfTokens,
            baseURIIndex
        );
    }

    /// @dev allows admin to pause / un-pause claims.
    function setClaimPauseStatus(bool _paused) external onlyRole(DEFAULT_ADMIN_ROLE) {
        claimIsPaused = _paused;
        emit ClaimPauseStatusUpdated(claimIsPaused);
    }

    /// @dev allows an admin to enable / disable the operator filterer.
    function setOperatorRestriction(bool _restriction)
        external
        override(IRestrictedOperatorFilterToggleV0, OperatorFilterToggle)
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        operatorRestriction = _restriction;
        emit OperatorRestriction(operatorRestriction);
    }

    function setOperatorFilterer(bytes32 _operatorFiltererId) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        IOperatorFiltererDataTypesV0.OperatorFilterer memory _newOperatorFilterer = aspenConfig
            .getOperatorFiltererOrDie(_operatorFiltererId);
        _setOperatorFilterer(_newOperatorFilterer);

        emit OperatorFiltererUpdated(_operatorFiltererId);
    }

    /// ======================================
    /// ============ Agreement ===============
    /// ======================================
    /// @notice allow an ISSUER to accept terms for an address
    function acceptTerms(address _acceptor) external override onlyRole(ISSUER_ROLE) {
        termsData.acceptTerms(_acceptor);
        emit TermsAcceptedForAddress(termsData.termsURI, termsData.termsVersion, _acceptor, _msgSender());
    }

    /// @notice allows an ISSUER to batch accept terms on behalf of multiple users
    function batchAcceptTerms(address[] calldata _acceptors) external onlyRole(ISSUER_ROLE) {
        for (uint256 i = 0; i < _acceptors.length; i++) {
            termsData.acceptTerms(_acceptors[i]);
            emit TermsAcceptedForAddress(termsData.termsURI, termsData.termsVersion, _acceptors[i], _msgSender());
        }
    }

    /// @notice activates / deactivates the terms of use.
    function setTermsActivation(bool _active) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        termsData.setTermsActivation(_active);
        emit TermsActivationStatusUpdated(_active);
    }

    /// @notice updates the term URI and pumps the terms version
    function setTermsURI(string calldata _termsURI) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        termsData.setTermsURI(_termsURI);
        emit TermsUpdated(_termsURI, termsData.termsVersion);
    }

    /// @notice allows anyone to accept terms on behalf of a user, as long as they provide a valid signature
    function acceptTerms(address _acceptor, bytes calldata _signature) external override {
        if (!_verifySignature(termsData, _acceptor, _signature)) revert IDropErrorsV0.SignatureVerificationFailed();
        termsData.acceptTerms(_acceptor);
        emit TermsWithSignatureAccepted(termsData.termsURI, termsData.termsVersion, _acceptor, _signature);
    }

    /// @notice verifies a signature
    /// @dev this function takes the signers address and the signature signed with their private key.
    ///     ECDSA checks whether a hash of the message was signed by the user's private key.
    ///     If yes, the _to address == ECDSA's returned address
    function _verifySignature(
        TermsDataTypes.Terms storage termsData,
        address _acceptor,
        bytes memory _signature
    ) internal view returns (bool) {
        if (_signature.length == 0) return false;
        bytes32 hash = _hashMessage(termsData, _acceptor);
        address signer = ECDSAUpgradeable.recover(hash, _signature);
        return signer == _acceptor;
    }

    /// ======================================
    /// ========= Delegated Logic ============
    /// ======================================
    /// @dev Returns the platform fee recipient and bps.
    function getPlatformFeeInfo() external view override returns (address platformFeeRecipient, uint16 platformFeeBps) {
        return aspenConfig.getPlatformFees();
    }

    /// @dev Returns the claim condition at the given uid.
    function getClaimConditionById(uint256 _tokenId, uint256 _conditionId)
        external
        view
        isValidTokenId(_tokenId)
        returns (ClaimCondition memory condition)
    {
        condition = AspenERC1155DropLogic.getClaimConditionById(claimData, _tokenId, _conditionId);
    }

    /// @dev Returns an array with all the claim conditions.
    function getClaimConditions(uint256 _tokenId)
        external
        view
        isValidTokenId(_tokenId)
        returns (ClaimCondition[] memory conditions)
    {
        conditions = AspenERC1155DropLogic.getClaimConditions(claimData, _tokenId);
    }

    /// @dev Returns basic info for claim data
    function getClaimData(uint256 _tokenId)
        external
        view
        returns (
            uint256 nextTokenIdToMint,
            uint256 maxTotalSupply,
            uint256 maxWalletClaimCount
        )
    {
        (nextTokenIdToMint, maxTotalSupply, maxWalletClaimCount) = AspenERC1155DropLogic.getClaimData(
            claimData,
            _tokenId
        );
    }

    /// @dev Returns the amount of stored baseURIs
    function getBaseURICount() external view returns (uint256) {
        return claimData.baseURIIndices.length;
    }

    /// @dev Expose the user specific limits related to the current active claim condition
    function getUserClaimConditions(uint256 _tokenId, address _claimer)
        external
        view
        override
        isValidTokenId(_tokenId)
        returns (
            ClaimCondition memory condition,
            uint256 conditionId,
            uint256 walletMaxClaimCount,
            uint256 tokenSupply,
            uint256 maxTotalSupply,
            uint256 walletClaimedCount,
            uint256 walletClaimedCountInPhase,
            uint256 lastClaimTimestamp,
            uint256 nextValidClaimTimestamp,
            bool isClaimPaused
        )
    {
        (condition, conditionId, walletMaxClaimCount, maxTotalSupply) = AspenERC1155DropLogic.getActiveClaimConditions(
            claimData,
            _tokenId
        );
        (
            conditionId,
            walletClaimedCount,
            walletClaimedCountInPhase,
            lastClaimTimestamp,
            nextValidClaimTimestamp
        ) = AspenERC1155DropLogic.getUserClaimConditions(claimData, _tokenId, _claimer);
        isClaimPaused = claimIsPaused;
        tokenSupply = claimData.totalSupply[_tokenId];
    }

    /// @dev Checks a request to claim NFTs against the active claim condition's criteria
    ///     including verification proofs.
    function verifyClaim(
        address _receiver,
        uint256 _tokenId,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bytes32[] calldata _proofs,
        uint256 _proofMaxQuantityPerTransaction
    ) public view override isValidTokenId(_tokenId) {
        AspenERC1155DropLogic.fullyVerifyClaim(
            claimData,
            _receiver,
            _tokenId,
            _quantity,
            _currency,
            _pricePerToken,
            _proofs,
            _proofMaxQuantityPerTransaction
        );
    }

    /// @dev Returns the offset for token IDs.
    function getSmallestTokenId() external pure override returns (uint8) {
        return TOKEN_INDEX_OFFSET;
    }

    /// @dev returns the total number of unique tokens in existence.
    function getLargestTokenId() public view override returns (uint256) {
        return claimData.nextTokenIdToMint - TOKEN_INDEX_OFFSET;
    }

    /// @dev returns the pause status of the drop contract.
    function getClaimPauseStatus() external view override returns (bool pauseStatus) {
        pauseStatus = claimIsPaused;
    }

    /// @dev Gets the base URI indices
    function getBaseURIIndices() external view override returns (uint256[] memory) {
        return claimData.baseURIIndices;
    }

    /// @dev this function hashes the terms url and message
    function _hashMessage(TermsDataTypes.Terms storage termsData, address _acceptor) private view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(MESSAGE_HASH, _acceptor, keccak256(bytes(termsData.termsURI)), termsData.termsVersion)
                )
            );
    }
}