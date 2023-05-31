// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.7;

//  ==========  External imports    ==========

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

//  ==========  Internal imports    ==========

import "./interfaces/IThirdwebContract.sol";

//  ==========  Features    ==========
import "./interfaces/IPlatformFee.sol";
import "./interfaces/IPrimarySale.sol";
import "./interfaces/IOwnable.sol";

import "./openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";
import "../generated/impl/BaseCedarERC721DropV3.sol";

import "./lib/FeeType.sol";
import "./lib/MerkleProof.sol";

import "../SignatureVerifier.sol";
import "../Agreement.sol";
import "../Greenlist.sol";

import "./errors/IErrors.sol";

import "./types/DataTypes.sol";
import "./lib/CedarDropERC721ClaimLogicV0.sol";

//  ==========  Cedar Features    ==========
contract CedarERC721Drop is
    Initializable,
    IThirdwebContract,
    IOwnable,
    IPrimarySale,
    ReentrancyGuardUpgradeable,
    ERC2771ContextUpgradeable,
    MulticallUpgradeable,
    AccessControlEnumerableUpgradeable,
    ERC721EnumerableUpgradeable,
    Agreement,
    Greenlist,
    IPlatformFee,
    BaseCedarERC721DropV3
{
    using BitMapsUpgradeable for BitMapsUpgradeable.BitMap;
    using StringsUpgradeable for uint256;

    using CedarDropERC721ClaimLogicV0 for DataTypes.ClaimData;

    /// @dev Emitted when the global max supply of tokens is updated.
    event MaxTotalSupplyUpdated(uint256 maxTotalSupply);

    /// @dev Emitted when the wallet claim count for an address is updated.
    event WalletClaimCountUpdated(address indexed wallet, uint256 count);

    /// @dev Emitted when the global max wallet claim count is updated.
    event MaxWalletClaimCountUpdated(uint256 count);

    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    bytes32 private constant MODULE_TYPE = bytes32("DropERC721");
    uint256 private constant VERSION = 2;

    /// @dev Only transfers to or from TRANSFER_ROLE holders are valid, when transfers are restricted.
    bytes32 private constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    /// @dev Only MINTER_ROLE holders can lazy mint NFTs.
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @dev Max bps in the thirdweb system.
    uint256 private constant MAX_BPS = 10_000;

    /// @dev Owner of the contract (purpose: OpenSea compatibility)
    address private _owner;

    /// @dev The (default) address that receives all royalty value.
    address private royaltyRecipient;

    /// @dev The (default) % of a sale to take as royalty (in basis points).
    uint16 private royaltyBps;

    /// @dev Contract level metadata.
    string public override(ICedarMetadataV0, IThirdwebContract) contractURI;

    /// @dev Largest tokenId of each batch of tokens with the same baseURI
    uint256[] public baseURIIndices;

    /// @dev The address that receives all platform fees from all sales.
    address private platformFeeRecipient;

    /// @dev The % of primary sales collected as platform fees.
    uint16 private platformFeeBps;

    DataTypes.ClaimData claimData;

    /*///////////////////////////////////////////////////////////////
                                Mappings
    //////////////////////////////////////////////////////////////*/

    /**
     *  @dev Mapping from 'Largest tokenId of a batch of tokens with the same baseURI'
     *       to base URI for the respective batch of tokens.
     **/
    mapping(uint256 => string) private baseURI;

    /// @dev Token ID => royalty recipient and bps for token
    mapping(uint256 => RoyaltyInfo) private royaltyInfoForToken;

    struct FeaturesInput {
        string userAgreement;
        address signatureVerifier;
        address greenlistManagerAddress;
    }

    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
    //////////////////////////////////////////////////////////////*/

    constructor() {}

    /// @dev Initiliazes the contract, like a constructor.
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
        __ERC2771Context_init(_trustedForwarders);
        __ERC721_init(_name, _symbol);

        __Agreement_init(featuresInput.userAgreement, featuresInput.signatureVerifier);
        __Greenlist_init(featuresInput.greenlistManagerAddress);

        // Initialize this contract's state.
        royaltyRecipient = _royaltyRecipient;
        royaltyBps = uint16(_royaltyBps);
        claimData.primarySaleRecipient = _saleRecipient;
        contractURI = _contractURI;
        _owner = _defaultAdmin;
        claimData.platformFeeRecipient = _platformFeeRecipient;
        claimData.platformFeeBps = uint16(_platformFeeBps);

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(MINTER_ROLE, _defaultAdmin);
        _setupRole(TRANSFER_ROLE, _defaultAdmin);
        _setupRole(TRANSFER_ROLE, address(0));
    }

    /*///////////////////////////////////////////////////////////////
                        Generic contract logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the type of the contract.
    function contractType() external pure override returns (bytes32) {
        return MODULE_TYPE;
    }

    /// @dev Returns the version of the contract.
    function contractVersion() external pure override returns (uint8) {
        return uint8(VERSION);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view override returns (address) {
        return hasRole(DEFAULT_ADMIN_ROLE, _owner) ? _owner : address(0);
    }

    /*///////////////////////////////////////////////////////////////
                        ERC 165 / 721 / 2981 logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the URI for a given tokenId.
    function tokenURI(uint256 _tokenId) public view override(ERC721Upgradeable, ICedarNFTMetadataV1) returns (string memory) {
        for (uint256 i = 0; i < baseURIIndices.length; i += 1) {
            if (_tokenId < baseURIIndices[i]) {
                return string(abi.encodePacked(baseURI[baseURIIndices[i]], _tokenId.toString()));
            }
        }

        return "";
    }

    /// @dev Returns the royalty recipient and amount, given a tokenId and sale price.
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

    /*///////////////////////////////////////////////////////////////
                    Minting logic
    //////////////////////////////////////////////////////////////*/

    /**
     *  @dev Lets an account with `MINTER_ROLE` lazy mint 'n' NFTs.
     *       The URIs for each token is the provided `_baseURIForTokens` + `{tokenId}`.
     */
    function lazyMint(
        uint256 _amount,
        string calldata _baseURIForTokens
    ) external override onlyRole(MINTER_ROLE) {
        uint256 startId = claimData.nextTokenIdToMint;
        uint256 baseURIIndex = startId + _amount;

        claimData.nextTokenIdToMint = baseURIIndex;
        baseURI[baseURIIndex] = _baseURIForTokens;
        baseURIIndices.push(baseURIIndex);

        emit TokensLazyMinted(startId, startId + _amount - 1, _baseURIForTokens);
    }

    /*///////////////////////////////////////////////////////////////
                            Claim logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Lets an account claim NFTs.
    function claim(
        address _receiver,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bytes32[] calldata _proofs,
        uint256 _proofMaxQuantityPerTransaction
    ) external payable override nonReentrant {
        if(!(isTrustedForwarder(msg.sender) || _msgSender() == tx.origin)) revert Bot();

        uint[] memory tokens = CedarDropERC721ClaimLogicV0.executeClaim(
            claimData, 
            _receiver, 
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
    }

    /// @dev Lets a contract admin (account with `DEFAULT_ADMIN_ROLE`) set claim conditions.
    function setClaimConditions(ClaimCondition[] calldata _phases, bool _resetClaimEligibility)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        CedarDropERC721ClaimLogicV0.setClaimConditions(claimData, _phases, _resetClaimEligibility);
    }

    /// @dev Checks whether a claimer meets the claim condition's allowlist criteria.
    function verifyClaimMerkleProof(
        uint256 _conditionId,
        address _claimer,
        uint256 _quantity,
        bytes32[] calldata _proofs,
        uint256 _proofMaxQuantityPerTransaction
    ) public view returns (bool validMerkleProof, uint256 merkleProofIndex) {
        return CedarDropERC721ClaimLogicV0.verifyClaimMerkleProof(claimData, _conditionId, _claimer, _quantity, _proofs, _proofMaxQuantityPerTransaction);
    }

    /// @dev Checks a request to claim NFTs against the active claim condition's criteria.
    function verifyClaim(
        uint256 _conditionId,
        address _claimer,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bool verifyMaxQuantityPerTransaction
    ) public override view {
        CedarDropERC721ClaimLogicV0.verifyClaim(claimData, _conditionId, _claimer, _quantity, _currency, _pricePerToken, verifyMaxQuantityPerTransaction);
    }

    /*///////////////////////////////////////////////////////////////
                        Getter functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the royalty recipient and bps for a particular token Id.
    function getRoyaltyInfoForToken(uint256 _tokenId) public view override returns (address, uint16) {
        RoyaltyInfo memory royaltyForToken = royaltyInfoForToken[_tokenId];

        return
            royaltyForToken.recipient == address(0)
                ? (royaltyRecipient, uint16(royaltyBps))
                : (royaltyForToken.recipient, uint16(royaltyForToken.bps));
    }

    /// @dev Returns the default royalty recipient and bps.
    function getDefaultRoyaltyInfo() external view override returns (address, uint16) {
        return (royaltyRecipient, uint16(royaltyBps));
    }

    /// @dev Returns the claim condition at the given uid.
    function getClaimConditionById(uint256 _conditionId) external view returns (ClaimCondition memory condition) {
        condition = claimData.claimCondition.phases[_conditionId];
    }

    /// @dev Returns the amount of stored baseURIs
    function getBaseURICount() external view returns (uint256) {
        return baseURIIndices.length;
    }

    /// @dev Expose the current active claim condition including claim limits
    function getActiveClaimConditions() external view override returns (ClaimCondition memory condition, uint256 conditionId, uint256 walletMaxClaimCount, uint256 remainingSupply) {
        return CedarDropERC721ClaimLogicV0.getActiveClaimConditions(claimData);
    }

    /// @dev Expose the user specific limits related to the current active claim condition
    function getUserClaimConditions(address _claimer) external view override returns (uint256 conditionId, uint256 walletClaimedCount, uint256 lastClaimTimestamp, uint256 nextValidClaimTimestamp) {
        return CedarDropERC721ClaimLogicV0.getUserClaimConditions(claimData, _claimer);
    }

    /*///////////////////////////////////////////////////////////////
                        Setter functions
    //////////////////////////////////////////////////////////////*/

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
        if(!(_maxTotalSupply < claimData.nextTokenIdToMint)) revert CrossedLimit();
        claimData.maxTotalSupply = _maxTotalSupply;
        emit MaxTotalSupplyUpdated(_maxTotalSupply);
    }

    /// @dev Lets a contract admin set the recipient for all primary sales.
    function setPrimarySaleRecipient(address _saleRecipient) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        claimData.primarySaleRecipient = _saleRecipient;
        emit PrimarySaleRecipientUpdated(_saleRecipient);
    }

    function primarySaleRecipient() external override view returns (address) {
        return claimData.primarySaleRecipient;
    }

    /// @dev Lets a contract admin update the default royalty recipient and bps.
    function setDefaultRoyaltyInfo(address _royaltyRecipient, uint256 _royaltyBps)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if(!(_royaltyBps <= MAX_BPS)) revert MaxBps();

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
         if(!(_bps <= MAX_BPS)) revert MaxBps();

        royaltyInfoForToken[_tokenId] = RoyaltyInfo({recipient: _recipient, bps: _bps});

        emit RoyaltyForToken(_tokenId, _recipient, _bps);
    }

    /// @dev Lets a contract admin set a new owner for the contract. The new owner must be a contract admin.
    function setOwner(address _newOwner) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!hasRole(DEFAULT_ADMIN_ROLE, _newOwner)) revert InvalidPermission();
        address _prevOwner = _owner;
        _owner = _newOwner;

        emit OwnerUpdated(_prevOwner, _newOwner);
    }

    /// @dev Lets a contract admin set the URI for contract-level metadata.
    function setContractURI(string calldata _uri) override (ICedarMetadataV0, IThirdwebContract) external onlyRole(DEFAULT_ADMIN_ROLE) {
        contractURI = _uri;
    }

    /*///////////////////////////////////////////////////////////////
                        Miscellaneous
    //////////////////////////////////////////////////////////////*/

    /// @dev Burns `tokenId`. See {ERC721-_burn}.
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        if(!(_isApprovedOrOwner(_msgSender(), tokenId))) revert InvalidPermission();
        _burn(tokenId);
    }

    /// @dev See {ERC721-_beforeTokenTransfer}.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);

        // if transfer is restricted on the contract, we still want to allow burning and minting
        if (!hasRole(TRANSFER_ROLE, address(0)) && from != address(0) && to != address(0)) {
            if(!(hasRole(TRANSFER_ROLE, from) || hasRole(TRANSFER_ROLE, to))) revert InvalidPermission();
        }

        if (to != address(this)) {
            address caller = getCaller();
            if (termsActivated) {
                require(
                    termsAccepted[to],
                    string(
                        abi.encodePacked(
                            "Receiver address has not accepted the collection's terms of use at ",
                            ownerDomain
                        )
                    )
                );
            }
            checkGreenlist(caller);
        }
    }

    /// @dev this function returns the address for the *direct* caller of this contract.
    function getCaller() internal view returns (address _caller) {
        assembly {
            _caller := caller()
        }
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

    // Agreement

    /// @notice activates the terms
    /// @dev this function activates the user terms
    function setTermsStatus(bool _status) external override virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _setTermsStatus(_status);
    }

    /// @notice switch on / off the greenlist
    /// @dev this function will allow only Aspen's asset proxy to transfer tokens
    function setGreenlistStatus(bool _status) external virtual  onlyRole(DEFAULT_ADMIN_ROLE) {
        _setGreenlistStatus(_status);
    }

    /// @notice stores terms accepted from a signed message
    /// @dev this function is for acceptors that have signed a message offchain to accept the terms. The function calls the verifier contract to valid the signature before storing acceptance.
    function storeTermsAccepted(address _acceptor, bytes calldata _signature) external override virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _storeTermsAccepted(_acceptor, _signature);
    }

    function setOwnerDomain(string calldata _ownerDomain) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _setOwnerDomain(_ownerDomain);
    }
    /* ========== VIEWS ========== */
    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(
            AccessControlEnumerableUpgradeable,
            ERC721EnumerableUpgradeable,
            BaseCedarERC721DropV3
        )
        returns (bool)
    {
        return ERC721EnumerableUpgradeable.supportsInterface(interfaceId);
    }

    // Concrete implementation semantic version - provided for completeness but not designed to be the point of dispatch
    function minorVersion() public pure override returns (uint256 minor, uint256 patch) {
        minor = 0;
        patch = 0;
    }

    function multicall(bytes[] calldata data)
        external
        override(IMulticallableV0, MulticallUpgradeable)
        returns (bytes[] memory results)
    {
        return MulticallUpgradeable(this).multicall(data);
    }

    /**
     *  @dev Lets an account with `MINTER_ROLE` update base URI.
     */
    function updateBaseURI(uint256 baseURIIndex, string calldata _baseURIForTokens) override external onlyRole(MINTER_ROLE) {
        baseURI[baseURIIndex] = _baseURIForTokens;
        emit BaseURIUpdated(baseURIIndex, _baseURIForTokens);
    }

    /**
     *  @dev Gets the base URI indices
     */
    function getBaseURIIndices() external override view returns(uint256[] memory) {
        return baseURIIndices;
    }

    /// @dev Returns the platform fee recipient and bps.
    function getPlatformFeeInfo() override external view returns (address, uint16) {
        return (claimData.platformFeeRecipient, uint16(claimData.platformFeeBps));
    }

    /// @dev Lets a contract admin update the platform fee recipient and bps
    function setPlatformFeeInfo(address _platformFeeRecipient, uint256 _platformFeeBps)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_platformFeeBps <= MAX_BPS, "> MAX_BPS.");

        claimData.platformFeeBps = uint16(_platformFeeBps);
        claimData.platformFeeRecipient = _platformFeeRecipient;

        emit PlatformFeeInfoUpdated(_platformFeeRecipient, _platformFeeBps);
    }
}