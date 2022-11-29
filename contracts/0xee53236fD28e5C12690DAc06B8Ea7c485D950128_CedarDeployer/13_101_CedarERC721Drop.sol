// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

/// ========== Features ==========
import "./interfaces/IPlatformFee.sol";
import "./interfaces/IOwnable.sol";

import "./openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";
import "../generated/impl/BaseCedarERC721DropV7.sol";

import "./lib/FeeType.sol";
import "./lib/MerkleProof.sol";

import "./errors/IErrors.sol";

import "./types/DropERC721DataTypes.sol";
import "./CedarERC721DropLogic.sol";

import "../terms/types/TermsDataTypes.sol";
import "../terms/lib/TermsLogic.sol";

import "./CedarERC721DropStorage.sol";
import "../api/issuance/INFTSupply.sol";
import "../api/metadata/ICedarNFTMetadata.sol";

/// @title The CedarERC721Drop contract
contract CedarERC721Drop is IPublicOwnable, IPublicPlatformFee, CedarERC721DropStorage, BaseCedarERC721DropV7 {
    /// ================================
    /// =========== Libraries ==========
    /// ================================
    using StringsUpgradeable for uint256;
    using CedarERC721DropLogic for DropERC721DataTypes.ClaimData;
    using TermsLogic for TermsDataTypes.Terms;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    /// ====================================================
    /// ========== Constructor + initializer logic =========
    /// ====================================================
    constructor() {}

    /// @dev Initializes the contract, like a constructor.
    function initialize(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address[] memory _trustedForwarders,
        address _saleRecipient,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        string memory _userAgreement,
        uint128 _platformFeeBps,
        address _platformFeeRecipient,
        address _drop1155DelegateLogic
    ) external initializer {
        // Initialize inherited contracts, most base-like -> most derived.
        __ReentrancyGuard_init();
        __ERC2771Context_init(_trustedForwarders);
        __ERC721_init(_name, _symbol);
        __DefaultOperatorFilterer_init();

        // Initialize this contract's state.
        claimData.royaltyRecipient = _royaltyRecipient;
        claimData.royaltyBps = uint16(_royaltyBps);
        _contractUri = _contractURI;
        _owner = _defaultAdmin;
        claimData.primarySaleRecipient = _saleRecipient;
        claimData.platformFeeRecipient = _platformFeeRecipient;
        claimData.platformFeeBps = uint16(_platformFeeBps);
        // Agreement initialize
        termsData.termsURI = _userAgreement;
        // We set the terms version to 1 if there is an actual termsURL
        if (bytes(_userAgreement).length > 0) {
            termsData.termsVersion = 1;
            termsData.termsActivated = true;
        }
        delegateLogicContract = _drop1155DelegateLogic;

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(MINTER_ROLE, _defaultAdmin);
        _setupRole(TRANSFER_ROLE, _defaultAdmin);
        _setupRole(TRANSFER_ROLE, address(0));
        _setupRole(ISSUER_ROLE, _defaultAdmin);

        emit OwnershipTransferred(address(0), _defaultAdmin);
    }

    fallback() external {
        // get facet from function selector
        address logic = delegateLogicContract;
        require(logic != address(0));
        // Execute external function from delegate logic contract using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), logic, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /// ============================================
    /// ========== Generic contract logic ==========
    /// ============================================
    /// @dev Returns the address of the current owner.
    function owner() public view override returns (address) {
        return hasRole(DEFAULT_ADMIN_ROLE, _owner) ? _owner : address(0);
    }

    /// @dev See {IERC721Enumerable-totalSupply}.
    function totalSupply() public view override(INFTSupplyV0, ERC721EnumerableUpgradeable) returns (uint256) {
        return ERC721EnumerableUpgradeable.totalSupply();
    }

    /// @dev See ERC 721 - Returns the URI for a given tokenId.
    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721Upgradeable, ICedarNFTMetadataV1)
        returns (string memory)
    {
        return CedarERC721DropLogic.tokenURI(claimData, _tokenId);
    }

    /// @dev See ERC-2891 - Returns the royalty recipient and amount, given a tokenId and sale price.
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        virtual
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return CedarERC721DropLogic.royaltyInfo(claimData, tokenId, salePrice);
    }

    /// @dev See ERC 165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(BaseCedarERC721DropV7, CedarERC721DropStorage)
        returns (bool)
    {
        return
            BaseCedarERC721DropV7.supportsInterface(interfaceId) ||
            CedarERC721DropStorage.supportsInterface(interfaceId);
    }

    /// ======================================
    /// ============= Claim logic ============
    /// ======================================
    /// @dev Lets an account claim NFTs.
    function claim(
        address _receiver,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bytes32[] calldata _proofs,
        uint256 _proofMaxQuantityPerTransaction
    ) external payable override nonReentrant {
        address msgSender = _msgSender();
        if (!(isTrustedForwarder(msg.sender) || msgSender == tx.origin)) revert Bot();
        if (claimIsPaused) revert ClaimPaused();

        (uint256[] memory tokens, CedarERC721DropLogic.InternalClaim memory internalClaim) = CedarERC721DropLogic
            .executeClaim(
                claimData,
                _quantity,
                _currency,
                _pricePerToken,
                _proofs,
                _proofMaxQuantityPerTransaction,
                _msgSender()
            );

        for (uint256 i = 0; i < tokens.length; i += 1) {
            _mint(_receiver, tokens[i]);
        }

        emit TokensClaimed(
            internalClaim.activeConditionId,
            msgSender,
            _receiver,
            internalClaim.tokenIdToClaim,
            _quantity
        );
    }

    /// @dev Checks a request to claim NFTs against the active claim condition's criteria.
    function verifyClaim(
        uint256 _conditionId,
        address _claimer,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bool verifyMaxQuantityPerTransaction
    ) public view override {
        CedarERC721DropLogic.verifyClaim(
            claimData,
            _conditionId,
            _claimer,
            _quantity,
            _currency,
            _pricePerToken,
            verifyMaxQuantityPerTransaction
        );
    }

    /// ======================================
    /// ============ Agreement ===============
    /// ======================================
    /// @notice by signing this transaction, you are confirming that you have read and agreed to the terms of use at `termsUrl`
    function acceptTerms() external override {
        termsData.acceptTerms(_msgSender());
        emit TermsAccepted(termsData.termsURI, termsData.termsVersion, _msgSender());
    }

    //    /// @notice allows anyone to accept the terms for a specific address, given that have a valid signature from the acceptor
    //    function acceptTerms(address _acceptor, bytes calldata _signature) external override {
    //        termsData.acceptTermsWithSignature(_acceptor, _signature);
    //        emit TermsAccepted(termsData.termsURI, termsData.termsVersion, _acceptor, _signature);
    //    }

    /// @notice returns the details of the terms
    /// @return termsURI - the URI of the terms
    /// @return termsVersion - the version of the terms
    /// @return termsActivated - the status of the terms
    function getTermsDetails()
        external
        view
        override
        returns (
            string memory termsURI,
            uint8 termsVersion,
            bool termsActivated
        )
    {
        return termsData.getTermsDetails();
    }

    /// @notice returns true if an address has accepted the terms
    function hasAcceptedTerms(address _address) external view override returns (bool hasAccepted) {
        hasAccepted = termsData.hasAcceptedTerms(_address);
    }

    /// @notice returns true if an address has accepted the terms
    function hasAcceptedTerms(address _address, uint8 _termsVersion) external view override returns (bool hasAccepted) {
        hasAccepted = termsData.hasAcceptedTerms(_address, _termsVersion);
    }

    /// ======================================
    /// ========== Getter functions ==========
    /// ======================================
    /// @dev Returns the sale recipient address.
    function primarySaleRecipient() external view override returns (address) {
        return claimData.primarySaleRecipient;
    }

    /// @dev Contract level metadata.
    function contractURI() external view override(IPublicMetadataV0) returns (string memory) {
        return _contractUri;
    }

    /// @dev Returns the platform fee recipient and bps.
    function getPlatformFeeInfo() external view override returns (address, uint16) {
        return (claimData.platformFeeRecipient, uint16(claimData.platformFeeBps));
    }

    /// @dev Returns the default royalty recipient and bps.
    function getDefaultRoyaltyInfo() external view override returns (address, uint16) {
        return (claimData.royaltyRecipient, uint16(claimData.royaltyBps));
    }

    /// @dev Returns the royalty recipient and bps for a particular token Id.
    function getRoyaltyInfoForToken(uint256 _tokenId) public view override returns (address, uint16) {
        return CedarERC721DropLogic.getRoyaltyInfoForToken(claimData, _tokenId);
    }

    /// @dev Returns the amount of stored baseURIs
    function getBaseURICount() external view returns (uint256) {
        return claimData.baseURIIndices.length;
    }

    /// @dev Gets the base URI indices
    function getBaseURIIndices() external view override returns (uint256[] memory) {
        return claimData.baseURIIndices;
    }

    /// @dev Returns the claim condition at the given uid.
    function getClaimConditionById(uint256 _conditionId) external view returns (ClaimCondition memory condition) {
        condition = CedarERC721DropLogic.getClaimConditionById(claimData, _conditionId);
    }

    /// @dev Expose the current active claim condition including claim limits
    function getActiveClaimConditions()
        external
        view
        override
        returns (
            ClaimCondition memory condition,
            uint256 conditionId,
            uint256 walletMaxClaimCount,
            uint256 maxTotalSupply,
            uint256 tokenSupply,
            bool isClaimPaused
        )
    {
        (condition, conditionId, walletMaxClaimCount, maxTotalSupply) = claimData.getActiveClaimConditions();
        isClaimPaused = claimIsPaused;
        tokenSupply = totalSupply();
    }

    /// @dev Expose the user specific limits related to the current active claim condition
    function getUserClaimConditions(address _claimer)
        external
        view
        override
        returns (
            uint256 conditionId,
            uint256 walletClaimedCount,
            uint256 walletClaimedCountInPhase,
            uint256 lastClaimTimestamp,
            uint256 nextValidClaimTimestamp
        )
    {
        return CedarERC721DropLogic.getUserClaimConditions(claimData, _claimer);
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    /// ======================================
    /// ==== OS Default Operator Filterer ====
    /// ======================================
    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721Upgradeable, IERC721Upgradeable) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721Upgradeable, IERC721Upgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721Upgradeable, IERC721Upgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /// ======================================
    /// =========== Miscellaneous ============
    /// ======================================
    /// @dev Concrete implementation semantic version -
    ///         provided for completeness but not designed to be the point of dispatch
    function minorVersion() public pure override returns (uint256 minor, uint256 patch) {
        minor = 1;
        patch = 0;
    }

    /// @dev Burns `tokenId`. See {ERC721-_burn}.
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        if (!(_isApprovedOrOwner(_msgSender(), tokenId))) revert InvalidPermission();
        _burn(tokenId);
        // Not strictly necessary since we shouldn't issue this token again
        claimData.tokenURIs[tokenId].sequenceNumber = 0;
    }

    /// @dev Provides a function to batch together multiple calls in a single external call.
    function multicall(bytes[] calldata data)
        external
        override(CedarERC721DropStorage, IMulticallableV0)
        returns (bytes[] memory results)
    {
        return MulticallUpgradeable(this).multicall(data);
    }

    function _msgSender() internal view virtual override returns (address sender) {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }
}