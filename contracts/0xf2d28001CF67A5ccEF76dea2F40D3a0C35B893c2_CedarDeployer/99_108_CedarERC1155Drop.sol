// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

//  ==========  External imports    ==========
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
/// ========== Internal imports ==========
import "./interfaces/IThirdwebContract.sol";

/// ========== Features ==========
import "./interfaces/IOwnable.sol";
import "./interfaces/IPlatformFee.sol";

import "./openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";
import "../generated/impl/BaseCedarERC1155DropV4.sol";

import "./lib/FeeType.sol";
import "./lib/MerkleProof.sol";

import "../Agreement.sol";

import "./errors/IErrors.sol";

import "./types/DropERC1155DataTypes.sol";
import "./CedarERC1155DropLogic.sol";

/// @title The CedarERC1155Drop contract
/// @dev TODO: Add more details
contract CedarERC1155Drop is
    Initializable,
    IThirdwebContract,
    IOwnable,
    ReentrancyGuardUpgradeable,
    ERC2771ContextUpgradeable,
    MulticallUpgradeable,
    AccessControlEnumerableUpgradeable,
    ERC1155Upgradeable,
    IPlatformFee,
    Agreement,
    BaseCedarERC1155DropV4
{
    /// ================================
    /// =========== Libraries ==========
    /// ================================
    using StringsUpgradeable for uint256;
    using CedarERC1155DropLogic for DropERC1155DataTypes.ClaimData;

    /// =============================
    /// =========== Events ==========
    /// =============================
    /// @dev Emitted when the global max supply of a token is updated.
    event MaxTotalSupplyUpdated(uint256 tokenId, uint256 maxTotalSupply);
    /// @dev Emitted when the wallet claim count for a given tokenId and address is updated.
    event WalletClaimCountUpdated(uint256 tokenId, address indexed wallet, uint256 count);
    /// @dev Emitted when the max wallet claim count for a given tokenId is updated.
    event MaxWalletClaimCountUpdated(uint256 tokenId, uint256 count);
    /// @dev Emitted when the sale recipient for a particular tokenId is updated.
    event SaleRecipientForTokenUpdated(uint256 indexed tokenId, address saleRecipient);

    /// ===============================================
    /// =========== State variables - public ==========
    /// ===============================================
    /// @dev Token name
    string public name;
    /// @dev Token symbol
    string public symbol;
    /// @dev The address that receives all primary sales value.
    address public override primarySaleRecipient;
    /// @dev Only transfers to or from TRANSFER_ROLE holders are valid, when transfers are restricted.
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    /// @dev Only MINTER_ROLE holders can lazy mint NFTs.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    /// @dev Only ISSUER_ROLE holders can issue NFTs.
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    /// @dev If true, users cannot claim.
    bool public claimIsPaused = false;

    /// ================================================
    /// =========== State variables - private ==========
    /// ================================================
    uint256 private constant MAX_UINT256 = 2**256 - 1;
    bytes32 private constant MODULE_TYPE = bytes32("DropERC1155");
    uint256 private constant VERSION = 2;
    /// @dev Max bps in the thirdweb system
    uint256 private constant MAX_BPS = 10_000;
    /// @dev Owner of the contract (purpose: OpenSea compatibility)
    address private _owner;
    /// @dev The recipient of who gets the royalty.
    address private royaltyRecipient;
    /// @dev The (default) address that receives all royalty value.
    uint16 private royaltyBps;
    /// @dev Contract level metadata.
    string private _contractUri;
    /// @dev Largest tokenId of each batch of tokens with the same baseURI
    uint256[] private baseURIIndices;

    /// ===============================
    /// =========== Mappings ==========
    /// ===============================
    /// @dev Mapping from 'Largest tokenId of a batch of tokens with the same baseURI'
    ///         to base URI for the respective batch of tokens.
    mapping(uint256 => string) private baseURI;
    /// @dev Mapping from token ID => royalty recipient and bps for tokens of the token ID.
    mapping(uint256 => RoyaltyInfo) private royaltyInfoForToken;

    DropERC1155DataTypes.ClaimData claimData;

    /// =============================
    /// ========== Structs ==========
    /// =============================
    struct FeaturesInput {
        string userAgreement;
        address signatureVerifier;
    }

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
        FeaturesInput memory featuresInput,
        uint128 _platformFeeBps,
        address _platformFeeRecipient
    ) external initializer {
        // Initialize inherited contracts, most base-like -> most derived.
        __ReentrancyGuard_init();
        __ERC2771Context_init_unchained(_trustedForwarders);
        __ERC1155_init_unchained("");

        __Agreement_init(featuresInput.userAgreement, featuresInput.signatureVerifier);

        // Initialize this contract's state.
        name = _name;
        symbol = _symbol;
        royaltyRecipient = _royaltyRecipient;
        royaltyBps = uint16(_royaltyBps);
        primarySaleRecipient = _saleRecipient;
        _owner = _defaultAdmin;
        _contractUri = _contractURI;
        claimData.platformFeeRecipient = _platformFeeRecipient;
        claimData.platformFeeBps = uint16(_platformFeeBps);

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(MINTER_ROLE, _defaultAdmin);
        _setupRole(TRANSFER_ROLE, _defaultAdmin);
        _setupRole(TRANSFER_ROLE, address(0));
        _setupRole(ISSUER_ROLE, _defaultAdmin);
    }

    /// ============================================
    /// ========== Generic contract logic ==========
    /// ============================================
    /// @dev Returns the type of the contract.
    function contractType() external pure override returns (bytes32) {
        return MODULE_TYPE;
    }

    /// @dev Returns the version of the contract.
    function contractVersion() external pure override returns (uint8) {
        return uint8(VERSION);
    }

    /// @dev Returns the address of the current owner.
    function owner() public view override returns (address) {
        return hasRole(DEFAULT_ADMIN_ROLE, _owner) ? _owner : address(0);
    }

    /// @dev See ERC 1155 - Returns the URI for a given tokenId.
    function uri(uint256 _tokenId) public view override returns (string memory _tokenURI) {
        for (uint256 i = 0; i < baseURIIndices.length; i += 1) {
            if (_tokenId < baseURIIndices[i]) {
                return string(abi.encodePacked(baseURI[baseURIIndices[i]], _tokenId.toString()));
            }
        }

        return "";
    }

    /// @dev See ERC-2891 - Returns the royalty recipient and amount, given a tokenId and sale price.
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        virtual
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        (address recipient, uint256 bps) = getRoyaltyInfoForToken(tokenId);
        receiver = recipient;
        royaltyAmount = (salePrice * bps) / MAX_BPS;
    }

    /// @dev See ERC 165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(BaseCedarERC1155DropV4, ERC1155Upgradeable, AccessControlEnumerableUpgradeable)
        returns (bool)
    {
        return
            BaseCedarERC1155DropV4.supportsInterface(interfaceId) ||
            ERC1155Upgradeable.supportsInterface(interfaceId) ||
            AccessControlEnumerableUpgradeable.supportsInterface(interfaceId);
    }

    // More pointless yet required overrides
    function totalSupply(uint256 _tokenId) public view override returns (uint256) {
        return claimData.totalSupply[_tokenId];
    }

    function exists(uint256 _tokenId) public view override returns (bool) {
        return claimData.totalSupply[_tokenId] > 0;
    }

    /// @dev returns the total number of unique tokens in existence.
    function getLargestTokenId() public view override returns (uint256) {
        return claimData.nextTokenIdToMint - 1;
    }

    /// @dev allows admin to pause users from claiming.
    function pauseClaims() external onlyRole(DEFAULT_ADMIN_ROLE) {
        claimIsPaused = true;
        emit ClaimPauseStatusUpdated(claimIsPaused);
    }

    /// @dev allows admin to un-pause users from claiming.
    function unpauseClaims() external onlyRole(DEFAULT_ADMIN_ROLE) {
        claimIsPaused = false;
        emit ClaimPauseStatusUpdated(claimIsPaused);
    }

    /// ======================================
    /// =========== Minting logic ============
    /// ======================================
    /// @dev Lets an account with `MINTER_ROLE` lazy mint 'n' NFTs.
    ///        The URIs for each token is the provided `_baseURIForTokens` + `{tokenId}`.
    function lazyMint(uint256 _amount, string calldata _baseURIForTokens) external override onlyRole(MINTER_ROLE) {
        uint256 startId = claimData.nextTokenIdToMint;
        uint256 baseURIIndex = startId + _amount;

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
    /// ============= Claim logic ============
    /// ======================================
    /// @dev Lets an account claim a given quantity of NFTs, of a single tokenId.
    function claim(
        address _receiver,
        uint256 _tokenId,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bytes32[] calldata _proofs,
        uint256 _proofMaxQuantityPerTransaction
    ) external payable override nonReentrant {
        address msgSender = _msgSender();
        if (!(isTrustedForwarder(msg.sender) || msgSender == tx.origin)) revert Bot();
        if (claimIsPaused) revert ClaimPaused();

        CedarERC1155DropLogic.InternalClaim memory internalClaim = CedarERC1155DropLogic.executeClaim(
            claimData,
            _tokenId,
            _quantity,
            _currency,
            _pricePerToken,
            _proofs,
            _proofMaxQuantityPerTransaction,
            msgSender,
            primarySaleRecipient
        );
        _mint(_receiver, _tokenId, _quantity, "");
        emit TokensClaimed(internalClaim.activeConditionId, _tokenId, msgSender, _receiver, _quantity);
    }

    /// @dev Lets a contract admin (account with `DEFAULT_ADMIN_ROLE`) set claim conditions, for a tokenId.
    function setClaimConditions(
        uint256 _tokenId,
        ClaimCondition[] calldata _phases,
        bool _resetClaimEligibility
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        CedarERC1155DropLogic.setClaimConditions(claimData, _tokenId, _phases, _resetClaimEligibility);
        emit ClaimConditionsUpdated(_tokenId, _phases);
    }

    /// @dev Checks a request to claim NFTs against the active claim condition's criteria.
    function verifyClaim(
        uint256 _conditionId,
        address _claimer,
        uint256 _tokenId,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bool verifyMaxQuantityPerTransaction
    ) public view override {
        CedarERC1155DropLogic.verifyClaim(
            claimData,
            _conditionId,
            _claimer,
            _tokenId,
            _quantity,
            _currency,
            _pricePerToken,
            verifyMaxQuantityPerTransaction
        );
    }

    /// ======================================
    /// ========== Setter functions ==========
    /// ======================================
    /// @dev Lets a contract admin set a new owner for the contract. The new owner must be a contract admin.
    function setOwner(address _newOwner) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!(hasRole(DEFAULT_ADMIN_ROLE, _newOwner))) revert InvalidPermission();
        emit OwnerUpdated(_owner, _newOwner);
        _owner = _newOwner;
    }

    /// @dev Lets a contract admin set the recipient for all primary sales.
    function setPrimarySaleRecipient(address _saleRecipient) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        primarySaleRecipient = _saleRecipient;
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
        if (!(_platformFeeBps <= MAX_BPS)) revert MaxBps();

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
        if (!(_royaltyBps <= MAX_BPS)) revert MaxBps();

        royaltyRecipient = _royaltyRecipient;
        royaltyBps = uint16(_royaltyBps);

        emit DefaultRoyalty(_royaltyRecipient, _royaltyBps);
    }

    /// @dev Lets a contract admin set the royalty recipient and bps for a particular token Id.
    function setRoyaltyInfoForToken(
        uint256 _tokenId,
        address _recipient,
        uint256 _bps
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!(_bps <= MAX_BPS)) revert MaxBps();

        royaltyInfoForToken[_tokenId] = RoyaltyInfo({recipient: _recipient, bps: _bps});

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
    function setContractURI(string calldata _uri)
        external
        override(ICedarMetadataV1, IThirdwebContract)
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _contractUri = _uri;
        emit ContractURIUpdated(_msgSender(), _uri);
    }

    /// @dev Lets an account with `MINTER_ROLE` update base URI.
    function updateBaseURI(uint256 baseURIIndex, string calldata _baseURIForTokens)
        external
        override
        onlyRole(MINTER_ROLE)
    {
        baseURI[baseURIIndex] = _baseURIForTokens;
        emit BaseURIUpdated(baseURIIndex, _baseURIForTokens);
    }

    /// ======================================
    /// ============ Agreement ===============
    /// ======================================
    /// @dev this function activates the user terms
    function setTermsStatus(bool _status) external virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        _setTermsStatus(_status);
    }

    /// @notice stores terms accepted from a signed message
    /// @dev this function is for acceptors that have signed a message offchain to accept the terms. The function calls the verifier contract to valid the signature before storing acceptance.
    function storeTermsAccepted(address _acceptor, bytes calldata _signature)
        external
        virtual
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _storeTermsAccepted(_acceptor, _signature);
    }

    /// ======================================
    /// ========== Getter functions ==========
    /// ======================================
    /// @dev Returns the platform fee recipient and bps.
    function getPlatformFeeInfo() external view override returns (address, uint16) {
        return (claimData.platformFeeRecipient, uint16(claimData.platformFeeBps));
    }

    /// @dev Returns the default royalty recipient and bps.
    function getDefaultRoyaltyInfo() external view override returns (address, uint16) {
        return (royaltyRecipient, uint16(royaltyBps));
    }

    /// @dev Returns the royalty recipient and bps for a particular token Id.
    function getRoyaltyInfoForToken(uint256 _tokenId) public view override returns (address, uint16) {
        RoyaltyInfo memory royaltyForToken = royaltyInfoForToken[_tokenId];

        return
            royaltyForToken.recipient == address(0)
                ? (royaltyRecipient, uint16(royaltyBps))
                : (royaltyForToken.recipient, uint16(royaltyForToken.bps));
    }

    /// @dev At any given moment, returns the uid for the active claim condition, for a given tokenId.
    function getActiveClaimConditionId(uint256 _tokenId) internal view returns (uint256) {
        return CedarERC1155DropLogic.getActiveClaimConditionId(claimData, _tokenId);
    }

    /// @dev Expose the current active claim condition including claim limits
    function getActiveClaimConditions(uint256 _tokenId)
        external
        view
        override
        returns (
            ClaimCondition memory condition,
            uint256 conditionId,
            uint256 walletMaxClaimCount,
            uint256 remainingSupply,
            bool isClaimPaused
        )
    {
        (condition, conditionId, walletMaxClaimCount, remainingSupply) = claimData.getActiveClaimConditions(_tokenId);
        isClaimPaused = claimIsPaused;
    }

    /// @dev Expose the user specific limits related to the current active claim condition
    function getUserClaimConditions(uint256 _tokenId, address _claimer)
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
        conditionId = getActiveClaimConditionId(_tokenId);
        (lastClaimTimestamp, nextValidClaimTimestamp) = getClaimTimestamp(_tokenId, conditionId, _claimer);
        walletClaimedCount = claimData.walletClaimCount[_tokenId][_claimer];
        walletClaimedCountInPhase = claimData.claimCondition[_tokenId].userClaims[conditionId][_claimer].claimedBalance;
    }

    /// @dev Returns the timestamp for when a claimer is eligible for claiming NFTs again.
    function getClaimTimestamp(
        uint256 _tokenId,
        uint256 _conditionId,
        address _claimer
    ) public view returns (uint256 lastClaimTimestamp, uint256 nextValidClaimTimestamp) {
        return CedarERC1155DropLogic.getClaimTimestamp(claimData, _tokenId, _conditionId, _claimer);
    }

    /// @dev Gets the base URI indices
    function getBaseURIIndices() external view override returns (uint256[] memory) {
        return baseURIIndices;
    }

    /// @dev Contract level metadata.
    function contractURI() external view override(ICedarMetadataV1, IThirdwebContract) returns (string memory) {
        return _contractUri;
    }

    /// ======================================
    /// =========== Miscellaneous ============
    /// ======================================
    /// @dev Concrete implementation semantic version -
    ///         provided for completeness but not designed to be the point of dispatch
    function minorVersion() public pure override returns (uint256 minor, uint256 patch) {
        minor = 0;
        patch = 0;
    }

    /// @dev Lets a token owner burn the tokens they own (i.e. destroy for good)
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        if (!(account == _msgSender() || isApprovedForAll(account, _msgSender()))) revert InvalidPermission();
        _burn(account, id, value);
    }

    /// @dev Lets a token owner burn multiple tokens they own at once (i.e. destroy for good)
    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        if (!(account == _msgSender() || isApprovedForAll(account, _msgSender()))) revert InvalidPermission();
        _burnBatch(account, ids, values);
    }

    /// @dev See {ERC1155-_beforeTokenTransfer}.
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        // if transfer is restricted on the contract, we still want to allow burning and minting
        if (!hasRole(TRANSFER_ROLE, address(0)) && from != address(0) && to != address(0)) {
            if (!(hasRole(TRANSFER_ROLE, from) || hasRole(TRANSFER_ROLE, to))) revert InvalidPermission();
        }

        if (to != address(this)) {
            if (termsActivated) {
                require(
                    termsAccepted[to],
                    string(
                        abi.encodePacked(
                            "Receiver address has not accepted the collection's terms of use at ",
                            userAgreement
                        )
                    )
                );
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

    /// @dev Provides a function to batch together multiple calls in a single external call.
    function multicall(bytes[] calldata data)
        external
        override(IMulticallableV0, MulticallUpgradeable)
        returns (bytes[] memory results)
    {
        return MulticallUpgradeable(this).multicall(data);
    }

    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }
}