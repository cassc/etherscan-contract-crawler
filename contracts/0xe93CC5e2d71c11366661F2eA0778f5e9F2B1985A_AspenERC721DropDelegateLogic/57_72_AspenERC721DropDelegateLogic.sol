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

import "./AspenERC721DropStorage.sol";
import "../generated/impl/BaseAspenERC721DropV2.sol";
import "./AspenERC721DropLogic.sol";
import "./../api/issuance/IDropClaimCondition.sol";

contract AspenERC721DropDelegateLogic is IDropClaimConditionV1, AspenERC721DropStorage, IDelegateBaseAspenERC721DropV2 {
    /// ================================
    /// =========== Libraries ==========
    /// ================================
    using StringsUpgradeable for uint256;
    using AspenERC721DropLogic for DropERC721DataTypes.ClaimData;
    using TermsLogic for TermsDataTypes.Terms;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    constructor() {}

    function initialize() external initializer {}

    /// @dev See ERC 165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return AspenERC721DropStorage.supportsInterface(interfaceId);
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
        if (!_exists(_tokenId)) revert IDropErrorsV0.InvalidTokenId(_tokenId);
        if (claimData.tokenURIs[_tokenId].isPermanent) revert IDropErrorsV0.FrozenTokenMetadata(_tokenId);
        AspenERC721DropLogic.setTokenURI(claimData, _tokenId, _tokenURI, isPermanent);
        emit TokenURIUpdated(_tokenId, _msgSender(), _tokenURI);
        emit MetadataUpdate(_tokenId);
    }

    /// ======================================
    /// =========== Minting logic ============
    /// ======================================
    /// @dev Lets an account with `MINTER_ROLE` lazy mint 'n' NFTs.
    ///        The URIs for each token is the provided `_baseURIForTokens` + `{tokenId}`.
    function lazyMint(uint256 _amount, string calldata _baseURIForTokens) external override onlyRole(MINTER_ROLE) {
        (uint256 startId, uint256 baseURIIndex) = AspenERC721DropLogic.lazyMint(claimData, _amount, _baseURIForTokens);
        emit TokensLazyMinted(startId, baseURIIndex - TOKEN_INDEX_OFFSET, _baseURIForTokens);
    }

    /// ======================================
    /// ============= Issue logic ============
    /// ======================================
    /// @dev Lets an issuer account to issue a given quantity of NFTs, of a single tokenId.
    function issue(address _receiver, uint256 _quantity) external override onlyRole(ISSUER_ROLE) {
        uint256[] memory tokenIds = AspenERC721DropLogic.verifyIssue(claimData, _quantity);
        _issue(_receiver, _quantity, tokenIds);
    }

    /// @dev Lets an issuer account to issue an NFT with a specific token uri.
    function issueWithTokenURI(address _receiver, string calldata _tokenURI) external override onlyRole(ISSUER_ROLE) {
        uint256[] memory tokenIds = AspenERC721DropLogic.verifyIssue(claimData, 1);
        _issueWithTokenURI(_receiver, _tokenURI, tokenIds[0]);
    }

    function issueWithinPhase(address _receiver, uint256 _quantity) external override onlyRole(ISSUER_ROLE) {
        uint256[] memory tokenIds = AspenERC721DropLogic.issueWithinPhase(claimData, _receiver, _quantity);
        _issue(_receiver, _quantity, tokenIds);
    }

    function issueWithinPhaseWithTokenURI(address _receiver, string calldata _tokenURI)
        external
        override
        onlyRole(ISSUER_ROLE)
    {
        uint256[] memory tokenIds = AspenERC721DropLogic.issueWithinPhase(claimData, _receiver, 1);
        _issueWithTokenURI(_receiver, _tokenURI, tokenIds[0]);
    }

    function _issue(
        address _receiver,
        uint256 _quantity,
        uint256[] memory _tokenIds
    ) internal {
        for (uint256 i = 0; i < _tokenIds.length; i += 1) {
            _mint(_receiver, _tokenIds[i]);
        }
        emit TokensIssued(_tokenIds[0], _msgSender(), _receiver, _quantity);
    }

    function _issueWithTokenURI(
        address _receiver,
        string calldata _tokenURI,
        uint256 _tokenId
    ) internal {
        // First mint the token
        _mint(_receiver, _tokenId);
        // Then set the tokenURI
        _setTokenURI(_tokenId, _tokenURI, false);
        emit TokenIssued(_tokenId, _msgSender(), _receiver, _tokenURI);
    }

    /// ======================================
    /// ============= Admin logic ============
    /// ======================================
    /// @dev Lets a contract admin (account with `DEFAULT_ADMIN_ROLE`) set claim conditions.
    function setClaimConditions(ClaimCondition[] calldata _phases, bool _resetClaimEligibility)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        AspenERC721DropLogic.setClaimConditions(claimData, _phases, _resetClaimEligibility);
        emit ClaimConditionsUpdated(_phases);
    }

    /// @dev Lets a contract admin set a new owner for the contract.
    function setOwner(address _newOwner) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        address _prevOwner = _owner;
        _owner = _newOwner;

        emit OwnershipTransferred(_prevOwner, _newOwner);
    }

    /// @dev Lets a contract admin set the token name and symbol.
    function setTokenNameAndSymbol(string calldata name_, string calldata symbol_)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        __name = name_;
        __symbol = symbol_;

        emit TokenNameAndSymbolUpdated(_msgSender(), __name, __symbol);
    }

    /// @dev Lets a contract admin set the recipient for all primary sales.
    function setPrimarySaleRecipient(address _saleRecipient) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        claimData.primarySaleRecipient = _saleRecipient;
        emit PrimarySaleRecipientUpdated(_saleRecipient);
    }

    /// @dev Lets a contract admin update the default royalty recipient and bps.
    function setDefaultRoyaltyInfo(address _royaltyRecipient, uint256 _royaltyBps)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        AspenERC721DropLogic.setDefaultRoyaltyInfo(claimData, _royaltyRecipient, _royaltyBps);
        emit DefaultRoyalty(_royaltyRecipient, _royaltyBps);
    }

    /// @dev Lets a contract admin set the royalty recipient and bps for a particular token Id.
    function setRoyaltyInfoForToken(
        uint256 _tokenId,
        address _recipient,
        uint256 _bps
    ) external override isValidTokenId(_tokenId) onlyRole(DEFAULT_ADMIN_ROLE) {
        AspenERC721DropLogic.setRoyaltyInfoForToken(claimData, _tokenId, _recipient, _bps);
        emit RoyaltyForToken(_tokenId, _recipient, _bps);
    }

    /// @dev Lets a contract admin set a claim count for a wallet.
    function setWalletClaimCount(address _claimer, uint256 _count) external onlyRole(DEFAULT_ADMIN_ROLE) {
        claimData.walletClaimCount[_claimer] = _count;
        emit WalletClaimCountUpdated(_claimer, _count);
    }

    /// @dev Lets a contract admin set a maximum number of NFTs that can be claimed by any wallet.
    function setMaxWalletClaimCount(uint256 _count) external onlyRole(DEFAULT_ADMIN_ROLE) {
        claimData.maxWalletClaimCount = _count;
        emit MaxWalletClaimCountUpdated(_count);
    }

    /// @dev Lets a contract admin set the global maximum supply for collection's NFTs.
    function setMaxTotalSupply(uint256 _maxTotalSupply) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_maxTotalSupply != 0 && claimData.nextTokenIdToMint - TOKEN_INDEX_OFFSET > _maxTotalSupply) {
            revert IDropErrorsV0.CrossedLimitMaxTotalSupply();
        }
        claimData.maxTotalSupply = _maxTotalSupply;
        emit MaxTotalSupplyUpdated(_maxTotalSupply);
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
    function getClaimConditionById(uint256 _conditionId) external view returns (ClaimCondition memory condition) {
        condition = AspenERC721DropLogic.getClaimConditionById(claimData, _conditionId);
    }

    /// @dev Returns an array with all the claim conditions.
    function getClaimConditions() external view returns (ClaimCondition[] memory conditions) {
        conditions = AspenERC721DropLogic.getClaimConditions(claimData);
    }

    /// @dev Returns basic info for claim data
    function getClaimData()
        external
        view
        returns (
            uint256 nextTokenIdToMint,
            uint256 maxTotalSupply,
            uint256 maxWalletClaimCount
        )
    {
        (nextTokenIdToMint, maxTotalSupply, maxWalletClaimCount) = AspenERC721DropLogic.getClaimData(claimData);
    }

    /// @dev Returns the amount of stored baseURIs
    function getBaseURICount() external view returns (uint256) {
        return claimData.baseURIIndices.length;
    }

    /// @dev Expose the user specific limits related to the current active claim condition
    function getUserClaimConditions(address _claimer)
        external
        view
        override
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
        (condition, conditionId, walletMaxClaimCount, maxTotalSupply) = AspenERC721DropLogic.getActiveClaimConditions(
            claimData
        );
        (
            conditionId,
            walletClaimedCount,
            walletClaimedCountInPhase,
            lastClaimTimestamp,
            nextValidClaimTimestamp
        ) = AspenERC721DropLogic.getUserClaimConditions(claimData, _claimer);
        isClaimPaused = claimIsPaused;
        tokenSupply = totalSupply();
    }

    /// @dev Checks a request to claim NFTs against the active claim condition's criteria
    ///     including verification proofs.
    function verifyClaim(
        address _receiver,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bytes32[] calldata _proofs,
        uint256 _proofMaxQuantityPerTransaction
    ) public view override {
        AspenERC721DropLogic.fullyVerifyClaim(
            claimData,
            _receiver,
            _quantity,
            _currency,
            _pricePerToken,
            _proofs,
            _proofMaxQuantityPerTransaction
        );
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