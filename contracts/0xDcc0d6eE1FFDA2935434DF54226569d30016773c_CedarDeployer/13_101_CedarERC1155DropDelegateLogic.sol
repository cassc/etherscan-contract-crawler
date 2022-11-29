// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

import "./CedarERC1155DropStorage.sol";
import "./../api/issuance/IDropClaimCondition.sol";
import "../generated/impl/BaseCedarERC1155DropV5.sol";

contract CedarERC1155DropDelegateLogic is
    IRestrictedOwnable,
    IRestrictedPlatformFee,
    CedarERC1155DropStorage,
    IDropClaimConditionV0,
    IDelegateBaseCedarERC1155DropV5
{
    /// ================================
    /// =========== Libraries ==========
    /// ================================
    using StringsUpgradeable for uint256;
    using TermsLogic for TermsDataTypes.Terms;
    using CedarERC1155DropLogic for DropERC1155DataTypes.ClaimData;

    constructor() {}

    function initialize() external initializer {
        // TODO: Anything we need to intialize here?
    }

    /// @dev See ERC 165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return CedarERC1155DropStorage.supportsInterface(interfaceId);
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
        if (_noOfTokenIds == 0) revert InvalidNoOfTokenIds();
        uint256 startId = claimData.nextTokenIdToMint;
        uint256 baseURIIndex = startId + _noOfTokenIds;

        claimData.nextTokenIdToMint = baseURIIndex;
        baseURI[baseURIIndex] = _baseURIForTokens;
        baseURIIndices.push(baseURIIndex);

        emit TokensLazyMinted(startId, baseURIIndex - 1, _baseURIForTokens);
    }

    /// ======================================
    /// ============= Issue logic ============
    /// ======================================
    /// @dev Lets an account claim a given quantity of NFTs, of a single tokenId.
    function issue(
        address _receiver,
        uint256 _tokenId,
        uint256 _quantity
    ) external override nonReentrant onlyRole(ISSUER_ROLE) {
        CedarERC1155DropLogic.verifyIssue(claimData, _tokenId, _quantity);

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
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        CedarERC1155DropLogic.setClaimConditions(claimData, _tokenId, _phases, _resetClaimEligibility);
        emit ClaimConditionsUpdated(_tokenId, _phases);
    }

    /// @dev Lets a contract admin set a new owner for the contract. The new owner must be a contract admin.
    function setOwner(address _newOwner) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!(hasRole(DEFAULT_ADMIN_ROLE, _newOwner))) revert InvalidPermission();
        address _prevOwner = _owner;
        _owner = _newOwner;
        emit OwnershipTransferred(_prevOwner, _newOwner);
    }

    /// @dev Lets a contract admin set the recipient for all primary sales.
    function setPrimarySaleRecipient(address _saleRecipient) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _primarySaleRecipient = _saleRecipient;
        emit PrimarySaleRecipientUpdated(_saleRecipient);
    }

    /// @dev Lets a contract admin set the recipient for all primary sales.
    function setSaleRecipientForToken(uint256 _tokenId, address _saleRecipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        claimData.saleRecipient[_tokenId] = _saleRecipient;
        emit SaleRecipientForTokenUpdated(_tokenId, _saleRecipient);
    }

    /// @dev Lets a contract admin update the platform fee recipient and bps
    function setPlatformFeeInfo(address _platformFeeRecipient, uint256 _platformFeeBps)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (!(_platformFeeBps <= CedarERC1155DropLogic.MAX_BPS)) revert MaxBps();

        claimData.platformFeeBps = uint16(_platformFeeBps);
        claimData.platformFeeRecipient = _platformFeeRecipient;

        emit PlatformFeeInfoUpdated(_platformFeeRecipient, _platformFeeBps);
    }

    /// @dev Lets a contract admin update the default royalty recipient and bps.
    function setDefaultRoyaltyInfo(address _royaltyRecipient, uint256 _royaltyBps)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        CedarERC1155DropLogic.setDefaultRoyaltyInfo(claimData, _royaltyRecipient, _royaltyBps);
        emit DefaultRoyalty(_royaltyRecipient, _royaltyBps);
    }

    /// @dev Lets a contract admin set the royalty recipient and bps for a particular token Id.
    function setRoyaltyInfoForToken(
        uint256 _tokenId,
        address _recipient,
        uint256 _bps
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        CedarERC1155DropLogic.setRoyaltyInfoForToken(claimData, _tokenId, _recipient, _bps);
        emit RoyaltyForToken(_tokenId, _recipient, _bps);
    }

    /// @dev Lets a contract admin set a claim count for a wallet.
    function setWalletClaimCount(
        uint256 _tokenId,
        address _claimer,
        uint256 _count
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        claimData.walletClaimCount[_tokenId][_claimer] = _count;
        emit WalletClaimCountUpdated(_tokenId, _claimer, _count);
    }

    /// @dev Lets a contract admin set a maximum number of NFTs of a tokenId that can be claimed by any wallet.
    function setMaxWalletClaimCount(uint256 _tokenId, uint256 _count) external onlyRole(DEFAULT_ADMIN_ROLE) {
        claimData.maxWalletClaimCount[_tokenId] = _count;
        emit MaxWalletClaimCountUpdated(_tokenId, _count);
    }

    /// @dev Lets a module admin set a max total supply for token.
    function setMaxTotalSupply(uint256 _tokenId, uint256 _maxTotalSupply) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_maxTotalSupply != 0 && claimData.totalSupply[_tokenId] > _maxTotalSupply) {
            revert CrossedLimitMaxTotalSupply();
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
        if (bytes(baseURI[baseURIIndex]).length == 0) revert BaseURIEmpty();
        baseURI[baseURIIndex] = _baseURIForTokens;
        emit BaseURIUpdated(baseURIIndex, _baseURIForTokens);
    }

    /// @dev allows admin to pause / un-pause claims.
    function setClaimPauseStatus(bool _paused) external onlyRole(DEFAULT_ADMIN_ROLE) {
        claimIsPaused = _paused;
        emit ClaimPauseStatusUpdated(claimIsPaused);
    }

    /// ======================================
    /// ============ Agreement ===============
    /// ======================================
    /// @notice allow an ISSUER to accept terms for an address
    function acceptTerms(address _acceptor) external override onlyRole(ISSUER_ROLE) {
        termsData.acceptTerms(_acceptor);
        emit TermsAccepted(termsData.termsURI, termsData.termsVersion, _acceptor);
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
}