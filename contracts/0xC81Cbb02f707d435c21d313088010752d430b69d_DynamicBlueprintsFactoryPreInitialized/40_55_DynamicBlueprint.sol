//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../abstract/HasSecondarySaleFees.sol";
import "../common/IRoyalty.sol";
import "../common/IOperatorFilterer.sol";
import "../common/Royalty.sol";
import "./interfaces/IDynamicBlueprint.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IOperatorFilterRegistry } from "../operatorFilter/IOperatorFilterRegistry.sol";

/**
 * @notice Async Art Dynamic Blueprint NFT contract with true creator provenance
 * @author Async Art, Ohimire Labs
 */
contract DynamicBlueprint is
    ERC721Upgradeable,
    HasSecondarySaleFees,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuard,
    Royalty,
    IDynamicBlueprint
{
    using StringsUpgradeable for uint256;

    /**
     * @notice First token ID of the next Blueprint to be minted
     */
    uint64 public latestErc721TokenIndex;

    /**
     * @notice Account representing platform
     */
    address public platform;

    /**
     * @notice Account able to perform actions restricted to MINTER_ROLE holder
     */
    address public minterAddress;

    /**
     * @notice Blueprint artist
     */
    address public artist;

    /**
     * @notice Blueprint, core object of contract
     */
    Blueprint public blueprint;

    /**
     * @notice Token Ids to custom, per-token, overriding token URIs
     */
    mapping(uint256 => DynamicBlueprintTokenURI) public tokenIdsToURI;

    /**
     * @notice Contract-level metadata
     */
    string public contractURI;

    /**
     * @notice Broadcast contract
     */
    address public broadcast;

    /**
     * @notice Holders of this role are given minter privileges
     */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @notice Holders of this role are given storefront minter privileges
     */
    bytes32 public constant STOREFRONT_MINTER_ROLE = keccak256("STOREFRONT_MINTER_ROLE");

    /**
     * @notice A registry to check for blacklisted operator addresses.
     *      Used to only permit marketplaces enforcing creator royalites if desired
     */
    IOperatorFilterRegistry public operatorFilterRegistry;

    /**
     * @notice Royalty config
     */
    Royalty private _royalty;

    /**
     * @notice Emitted when NFTs of blueprint are minted
     * @param tokenId NFT minted
     * @param newMintedCount New amount of tokens minted
     * @param recipient Recipent of minted NFTs
     */
    event BlueprintMinted(uint128 indexed tokenId, uint64 newMintedCount, address recipient);

    /**
     * @notice Emitted when blueprint is prepared
     * @param artist Blueprint artist
     * @param capacity Number of NFTs in blueprint
     * @param blueprintMetaData Blueprint metadata uri
     * @param baseTokenUri Blueprint's base token uri.
     *                     Token uris are a result of the base uri concatenated with token id (unless overriden)
     */
    event BlueprintPrepared(address indexed artist, uint64 capacity, string blueprintMetaData, string baseTokenUri);

    /**
     * @notice Emitted when blueprint token uri is updated
     * @param newBaseTokenUri New base uri
     */
    event BlueprintTokenUriUpdated(string newBaseTokenUri);

    /**
     * @notice Checks if blueprint is prepared
     */
    modifier isBlueprintPrepared() {
        require(blueprint.prepared, "!prepared");
        _;
    }

    /**
     * @notice Check if token is not soulbound. Revert if it is
     * @param tokenId ID of token being checked
     */
    modifier isNotSoulbound(uint256 tokenId) {
        require(!blueprint.isSoulbound, "is soulbound");
        _;
    }

    /////////////////////////////////////////////////
    /// Required for CORI Operator Registry //////
    /////////////////////////////////////////////////

    // Custom Error Type For Operator Registry Methods
    error OperatorNotAllowed(address operator);

    /**
     * @notice Restrict operators who are allowed to transfer these tokens
     * @param from Account that token is being transferred out of
     */
    modifier onlyAllowedOperator(address from) {
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    /**
     * @notice Restrict operators who are allowed to approve transfer delegates
     * @param operator Operator that is attempting to move tokens
     */
    modifier onlyAllowedOperatorApproval(address operator) {
        _checkFilterOperator(operator);
        _;
    }

    /**
     * @notice Initialize the instance
     * @param dynamicBlueprintsInput Core parameters for contract initialization
     * @param _platform Platform admin account
     * @param _minter Minter admin account
     * @param _royaltyParameters Initial royalty settings
     * @param storefrontMinters Addresses to be given STOREFRONT_MINTER_ROLE
     * @param _broadcast Broadcast contract that intents are emitted from
     * @param operatorFiltererInputs OpenSea operator filterer addresses
     */
    function initialize(
        DynamicBlueprintsInput calldata dynamicBlueprintsInput,
        address _platform,
        address _minter,
        Royalty calldata _royaltyParameters,
        address[] calldata storefrontMinters,
        address _broadcast,
        IOperatorFilterer.OperatorFiltererInputs calldata operatorFiltererInputs
    ) external initializer royaltyValid(_royaltyParameters) {
        // Intialize parent contracts
        ERC721Upgradeable.__ERC721_init(dynamicBlueprintsInput.name, dynamicBlueprintsInput.symbol);
        HasSecondarySaleFees._initialize();
        AccessControlUpgradeable.__AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, _platform);
        _setupRole(MINTER_ROLE, _minter);

        for (uint256 i = 0; i < storefrontMinters.length; i++) {
            _setupRole(STOREFRONT_MINTER_ROLE, storefrontMinters[i]);
        }

        platform = _platform;
        minterAddress = _minter;
        artist = dynamicBlueprintsInput.artist;

        contractURI = dynamicBlueprintsInput.contractURI;
        _royalty = _royaltyParameters;

        broadcast = _broadcast;

        if (operatorFiltererInputs.operatorFilterRegistryAddress != address(0)) {
            // Store OpenSea's operator filter registry, (passed as parameter to constructor for dependency injection)
            // On mainnet the filter registry will be: 0x000000000000AAeB6D7670E522A718067333cd4E
            operatorFilterRegistry = IOperatorFilterRegistry(operatorFiltererInputs.operatorFilterRegistryAddress);

            // Register contract address with the registry and subscribe to
            // CORI canonical filter-list (passed via constructor for dependency injection)
            // On mainnet the subscription address will be: 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6
            operatorFilterRegistry.registerAndSubscribe(
                address(this),
                operatorFiltererInputs.coriCuratedSubscriptionAddress
            );
        }
    }

    /**
     * @notice See {IDynamicBlueprint.prepareBlueprintAndCreateSale}
     */
    function prepareBlueprintAndCreateSale(
        BlueprintPreparationConfig calldata config,
        IStorefront.Sale memory sale,
        address storefront
    ) external override onlyRole(MINTER_ROLE) {
        require(blueprint.prepared == false, "already prepared");
        require(hasRole(STOREFRONT_MINTER_ROLE, storefront), "Storefront not authorized to mint");
        blueprint.capacity = config._capacity;

        _setupBlueprint(config._baseTokenUri, config._blueprintMetaData, config._isSoulbound);

        IStorefront(storefront).createSale(sale);

        _setBlueprintPrepared(config._blueprintMetaData);
    }

    /**
     * @notice See {IDynamicBlueprint.mintBlueprints}
     */
    function mintBlueprints(
        uint32 purchaseQuantity,
        address nftRecipient
    ) external override onlyRole(STOREFRONT_MINTER_ROLE) {
        Blueprint memory b = blueprint;
        // quantity must be available for minting
        require(b.mintedCount + purchaseQuantity <= b.capacity || b.capacity == 0, "quantity >");
        if (b.isSoulbound) {
            // if soulbound, can only mint one and the wallet must not already have a soulbound edition
            require(balanceOf(nftRecipient) == 0 && purchaseQuantity == 1, "max 1 soulbound/addr");
        }

        _mintQuantity(purchaseQuantity, nftRecipient);
    }

    /**
     * @notice See {IDynamicBlueprint.updateBlueprintArtist}
     */
    function updateBlueprintArtist(address _newArtist) external override onlyRole(MINTER_ROLE) {
        artist = _newArtist;
    }

    /**
     * @notice See {IDynamicBlueprint.updatePlatformAddress}
     */
    function updatePlatformAddress(address _platform) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(DEFAULT_ADMIN_ROLE, _platform);

        revokeRole(DEFAULT_ADMIN_ROLE, platform);
        platform = _platform;
    }

    /**
     * @notice See {IDynamicBlueprint.updateBlueprintCapacity}
     */
    function updateBlueprintCapacity(
        uint64 _newCapacity,
        uint64 _newLatestErc721TokenIndex
    ) external override onlyRole(MINTER_ROLE) {
        // why is this a requirement?
        require(blueprint.capacity > _newCapacity, "New cap too large");

        blueprint.capacity = _newCapacity;

        latestErc721TokenIndex = _newLatestErc721TokenIndex;
    }

    /**
     * @notice See {IDynamicBlueprint.updatePerTokenURI}
     */
    function updatePerTokenURI(uint256 _tokenId, string calldata _newURI) external override onlyRole(MINTER_ROLE) {
        require(_exists(_tokenId), "!minted");
        require(!tokenIdsToURI[_tokenId].isFrozen, "uri frozen");
        tokenIdsToURI[_tokenId].tokenURI = _newURI;
    }

    /**
     * @notice See {IDynamicBlueprint.lockPerTokenURI}
     */
    function lockPerTokenURI(uint256 _tokenId) external override {
        require(ownerOf(_tokenId) == msg.sender, "!owner");
        require(!tokenIdsToURI[_tokenId].isFrozen, "uri already frozen");
        tokenIdsToURI[_tokenId].isFrozen = true;
    }

    /**
     * @notice See {IDynamicBlueprint.updateBlueprintTokenUri}
     */
    function updateBlueprintTokenUri(
        string memory newBaseTokenUri
    ) external override onlyRole(MINTER_ROLE) isBlueprintPrepared {
        require(!blueprint.tokenUriLocked, "URI locked");

        blueprint.baseTokenUri = newBaseTokenUri;

        emit BlueprintTokenUriUpdated(newBaseTokenUri);
    }

    /**
     * @notice See {IDynamicBlueprint.updateBlueprintMetadataUri}
     */
    function updateBlueprintMetadataUri(
        string calldata newMetadataUri
    ) external override onlyRole(MINTER_ROLE) isBlueprintPrepared {
        require(!blueprint.metadataUriLocked, "metadata URI locked");
        blueprint.blueprintMetadata = newMetadataUri;
    }

    /**
     * @notice See {IDynamicBlueprint-updateOperatorFilterAndRegister}
     */
    function updateOperatorFilterAndRegister(
        address newRegistry,
        address coriCuratedSubscriptionAddress
    ) external override {
        updateOperatorFilterRegistryAddress(newRegistry);
        addOperatorFiltererSubscription(coriCuratedSubscriptionAddress);
    }

    ////////////////////////////
    /// ONLY ADMIN functions ///
    ////////////////////////////

    /**
     * @notice See {IDynamicBlueprint.lockBlueprintTokenUri}
     */
    function lockBlueprintTokenUri() external override onlyRole(DEFAULT_ADMIN_ROLE) isBlueprintPrepared {
        require(!blueprint.tokenUriLocked, "URI locked");

        blueprint.tokenUriLocked = true;
    }

    /**
     * @notice See {IDynamicBlueprint.lockBlueprintMetadataUri}
     */
    function lockBlueprintMetadataUri() external override onlyRole(DEFAULT_ADMIN_ROLE) {
        blueprint.metadataUriLocked = true;
    }

    /**
     * @notice See {IDynamicBlueprint.updateRoyalty}
     */
    function updateRoyalty(
        Royalty calldata newRoyalty
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) royaltyValid(newRoyalty) {
        _royalty = newRoyalty;
    }

    /**
     * @notice See {IDynamicBlueprint.updateMinterAddress}
     */
    function updateMinterAddress(address newMinterAddress) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MINTER_ROLE, newMinterAddress);

        revokeRole(MINTER_ROLE, minterAddress);
        minterAddress = newMinterAddress;
    }

    ////////////////////////////////////
    /// Secondary Fees implementation //
    ////////////////////////////////////

    /**
     * @notice See {IDynamicBlueprint.getFeeRecipients}
     */
    function getFeeRecipients(
        uint256 /* tokenId */
    ) external view override(HasSecondarySaleFees, IDynamicBlueprint) returns (address[] memory) {
        return _royalty.recipients;
    }

    /**
     * @notice See {IDynamicBlueprint.getFeeBps}
     */
    function getFeeBps(
        uint256 /* tokenId */
    ) external view override(HasSecondarySaleFees, IDynamicBlueprint) returns (uint32[] memory) {
        return _royalty.royaltyCutsBPS;
    }

    /**
     * @notice See {IDynamicBlueprint.metadataURI}
     */
    function metadataURI() external view virtual override isBlueprintPrepared returns (string memory) {
        return blueprint.blueprintMetadata;
    }

    /**
     * @notice Register this contract with the OpenSea operator registry. Subscribe to OpenSea's operator blacklist.
     * @param subscription An address that is currently registered with the operatorFiltererRegistry
     *                     that we will subscribe to.
     */
    function addOperatorFiltererSubscription(address subscription) public {
        require(owner() == msg.sender || artist == msg.sender, "unauthorized");
        operatorFilterRegistry.subscribe(address(this), subscription);
    }

    /**
     * @notice Update the address that the contract will make OperatorFilter checks against. When set to the zero
     *         address, checks will be bypassed.
     * @param newRegistry New address to make checks against
     */
    function updateOperatorFilterRegistryAddress(address newRegistry) public {
        require(owner() == msg.sender || artist == msg.sender, "unauthorized");
        operatorFilterRegistry = IOperatorFilterRegistry(newRegistry);
        if (newRegistry != address(0)) {
            operatorFilterRegistry.register(address(this));
        }
    }

    /**
     * @notice Override {IERC721-setApprovalForAll} to check against operator filter registry if it exists
     */
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @notice Override {IERC721-approve} to check against operator filter registry if it exists
     */
    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /**
     * @notice Override {IERC721-transferFrom} to check soulbound, and operator filter registry if it exists
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) isNotSoulbound(tokenId) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @notice Override {IERC721-safeTransferFrom} to check soulbound, and operator filter registry if it exists
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) isNotSoulbound(tokenId) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @notice Return token's uri
     * @param tokenId ID of token to return uri for
     * @return Token uri, constructed by taking base uri of blueprint, and concatenating token id (unless overridden)
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        string memory customTokenURI = tokenIdsToURI[tokenId].tokenURI;
        if (bytes(customTokenURI).length != 0) {
            // if a custom token URI has been registered, prefer it to the default
            return customTokenURI;
        }

        string memory baseURI = blueprint.baseTokenUri;
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, "/", tokenId.toString(), "/", "token.json"))
                : "";
    }

    /**
     * @notice Used for interoperability purposes (EIP-173)
     * @return Returns platform address as owner of contract
     */
    function owner() public view virtual returns (address) {
        return platform;
    }

    ////////////////////////////////////
    /// Required function overide //////
    ////////////////////////////////////

    /**
     * @notice ERC165 - Validate that the contract supports a interface
     * @param interfaceId ID of interface being validated
     * @return Returns true if contract supports interface
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721Upgradeable, ERC165StorageUpgradeable, AccessControlEnumerableUpgradeable)
        returns (bool)
    {
        return
            interfaceId == type(HasSecondarySaleFees).interfaceId ||
            ERC721Upgradeable.supportsInterface(interfaceId) ||
            ERC165StorageUpgradeable.supportsInterface(interfaceId) ||
            AccessControlEnumerableUpgradeable.supportsInterface(interfaceId);
    }

    /**
     * @notice Sets values after blueprint preparation
     * @param _blueprintMetaData Blueprint metadata uri
     */
    function _setBlueprintPrepared(string memory _blueprintMetaData) private {
        //assign the erc721 token index to the blueprint
        blueprint.erc721TokenIndex = latestErc721TokenIndex;
        blueprint.prepared = true;
        uint64 _capacity = blueprint.capacity;
        latestErc721TokenIndex += _capacity;

        emit BlueprintPrepared(artist, _capacity, _blueprintMetaData, blueprint.baseTokenUri);
    }

    /**
     * @notice Sets up core blueprint parameters
     * @param _baseTokenUri Base token uri for blueprint
     * @param _metadataUri Metadata uri for blueprint
     * @param _isSoulbound Denotes if tokens minted on blueprint are non-transferable
     */
    function _setupBlueprint(string memory _baseTokenUri, string memory _metadataUri, bool _isSoulbound) private {
        blueprint.baseTokenUri = _baseTokenUri;
        blueprint.blueprintMetadata = _metadataUri;

        if (_isSoulbound) {
            blueprint.isSoulbound = _isSoulbound;
        }
    }

    /**
     * @notice Mint a quantity of NFTs of blueprint to a recipient
     * @param _quantity Quantity to mint
     * @param _nftRecipient Recipient of minted NFTs
     */
    function _mintQuantity(uint32 _quantity, address _nftRecipient) private {
        uint128 newTokenId = blueprint.erc721TokenIndex;
        uint64 newMintedCount = blueprint.mintedCount;
        for (uint16 i; i < _quantity; i++) {
            _mint(_nftRecipient, newTokenId + i);
            emit BlueprintMinted(newTokenId + i, newMintedCount, _nftRecipient);
            ++newMintedCount;
        }

        blueprint.erc721TokenIndex += _quantity;
        blueprint.mintedCount = newMintedCount;
    }

    /**
     * @notice Check if operator can perform an action
     * @param operator Operator attempting to perform action
     */
    function _checkFilterOperator(address operator) private view {
        IOperatorFilterRegistry registry = operatorFilterRegistry;
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(registry) != address(0) && address(registry).code.length > 0) {
            if (!registry.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}