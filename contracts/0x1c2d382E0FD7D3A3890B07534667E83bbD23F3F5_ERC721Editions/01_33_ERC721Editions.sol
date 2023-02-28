// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./interfaces/IERC721Editions.sol";
import "./ERC721Base.sol";
import "../utils/Ownable.sol";
import "../metadata/interfaces/IMetadataRenderer.sol";
import "../metadata/interfaces/IEditionsMetadataRenderer.sol";
import "../auction/interfaces/IAuctionManager.sol";
import "./interfaces/IEditionCollection.sol";

import "../tokenManager/interfaces/IPostTransfer.sol";
import "../tokenManager/interfaces/IPostBurn.sol";
import "../utils/ERC721/ERC721Upgradeable.sol";
import "./interfaces/IERC721EditionMint.sol";
import "./MarketplaceFilterer/MarketplaceFilterer.sol";

/**
 * @title ERC721 Editions
 * @author [email protected], [email protected]
 * @notice Multiple Editions Per Collection
 */
contract ERC721Editions is
    IEditionCollection,
    IERC721Editions,
    IERC721EditionMint,
    ERC721Base,
    ERC721Upgradeable,
    MarketplaceFilterer
{
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * @notice Contract metadata
     */
    string public contractURI;

    /**
     * @notice Keeps track of next token ID
     */
    uint256 public nextTokenId;

    /**
     * @notice Generates metadata for contract and token
     */
    address private _metadataRendererAddress;

    /**
     * @notice Tracks current supply of each edition, edition indexed
     */
    uint256[] public editionCurrentSupply;

    /**
     * @notice Tracks size of each edition, edition indexed
     */
    uint256[] public editionMaxSupply;

    /**
     * @notice Tracks start token id each edition, edition indexed
     */
    uint256[] public editionStartId;

    /**
     * @notice Emitted when edition is created
     * @param editionId Edition ID
     * @param size Edition size
     * @param editionTokenManager Token manager for edition
     */
    event EditionCreated(uint256 indexed editionId, uint256 indexed size, address indexed editionTokenManager);

    /**
     * @notice Emitted when a number of copies of an edition are minted to a single recipient
     * @param editionId ID of edition
     * @param recipient Recipient of minted copies
     * @param amount Amount of minted copies
     */
    event EditionMintedToOneRecipient(uint256 indexed editionId, address indexed recipient, uint256 amount);

    /**
     * @notice Emitted when a number of copies of an edition are minted to a single recipient
     * @param editionId ID of edition
     * @param recipients Recipients of minted copies
     * @param amount Amount of minted copies to each recipient
     */
    event EditionMintedToRecipients(uint256 indexed editionId, address[] recipients, uint256 amount);

    /**
     * @notice Initialize the contract
     * @param creator Creator/owner of contract
     * @param defaultRoyalty Default royalty object for contract (optional)
     * @param _defaultTokenManager Default token manager for contract (optional)
     * @param _contractURI Contract metadata
     * @param _name Name of token edition
     * @param _symbol Symbol of the token edition
     * @param metadataRendererAddress Contract returning metadata for each edition
     * @param trustedForwarder Trusted minimal forwarder
     * @param initialMinters Initial minters to register
     * @param useMarketplaceFiltererRegistry Denotes whether to use marketplace filterer registry
     */
    function initialize(
        address creator,
        IRoyaltyManager.Royalty memory defaultRoyalty,
        address _defaultTokenManager,
        string memory _contractURI,
        string memory _name,
        string memory _symbol,
        address metadataRendererAddress,
        address trustedForwarder,
        address[] calldata initialMinters,
        bool useMarketplaceFiltererRegistry
    ) external initializer nonReentrant {
        _initialize(
            creator,
            defaultRoyalty,
            _defaultTokenManager,
            _contractURI,
            _name,
            _symbol,
            metadataRendererAddress,
            trustedForwarder,
            initialMinters,
            useMarketplaceFiltererRegistry
        );
    }

    /**
     * @notice Initialize the contract
     * @param data Contract initialization data
     * @ param creator Creator/owner of contract
     * @ param _contractURI Contract metadata
     * @ param _name Name of token edition
     * @ param _symbol Symbol of the token edition
     * @ param metadataRendererAddress Contract returning metadata for each edition
     * @ param trustedForwarder Trusted minimal forwarder
     * @ param initialMinters Initial minters to register
     * @ param useMarketplaceFiltererRegistry Denotes whether to use marketplace filterer registry
     */
    function initialize(bytes calldata data) external initializer nonReentrant {
        (
            address creator,
            string memory _contractURI,
            string memory _name,
            string memory _symbol,
            address metadataRendererAddress,
            address trustedForwarder,
            address[] memory initialMinters,
            bool useMarketplaceFiltererRegistry
        ) = abi.decode(data, (address, string, string, string, address, address, address[], bool));

        IRoyaltyManager.Royalty memory _defaultRoyalty = IRoyaltyManager.Royalty(address(0), 0);
        _initialize(
            creator,
            _defaultRoyalty,
            address(0),
            _contractURI,
            _name,
            _symbol,
            metadataRendererAddress,
            trustedForwarder,
            initialMinters,
            useMarketplaceFiltererRegistry
        );
    }

    /**
     * @notice Create edition
     * @param _editionInfo Info of the Edition
     * @param _editionSize Size of the Edition
     * @param _editionTokenManager Edition's token manager
     * @param editionRoyalty Edition royalty object for contract (optional)
     * @notice Used to create a new Edition within the Collection
     */
    function createEdition(
        bytes memory _editionInfo,
        uint256 _editionSize,
        address _editionTokenManager,
        IRoyaltyManager.Royalty memory editionRoyalty
    ) external onlyOwner nonReentrant returns (uint256) {
        uint256 editionId = _createEdition(_editionInfo, _editionSize, _editionTokenManager);
        if (editionRoyalty.recipientAddress != address(0)) {
            _royalties[editionId] = editionRoyalty;
        }

        return editionId;
    }

    /**
     * @notice Create edition with auction
     * @param _editionInfo Info of the Edition
     * @param auctionData Auction data
     * @param _editionTokenManager Edition's token manager
     * @param editionRoyalty Edition royalty object for contract (optional)
     * @notice Used to create a new 1/1 Edition Collection within the contract, and an auction for it
     */
    function createEditionWithAuction(
        bytes memory _editionInfo,
        bytes memory auctionData,
        address _editionTokenManager,
        IRoyaltyManager.Royalty memory editionRoyalty
    ) external onlyOwner nonReentrant returns (uint256) {
        uint256 editionId = _createEdition(_editionInfo, 1, _editionTokenManager);
        if (editionRoyalty.recipientAddress != address(0)) {
            _royalties[editionId] = editionRoyalty;
        }

        (
            address auctionManagerAddress,
            bytes32 auctionId,
            address auctionCurrency,
            address payable auctionPaymentRecipient,
            uint256 auctionEndTime
        ) = abi.decode(auctionData, (address, bytes32, address, address, uint256));

        IAuctionManager.EnglishAuction memory auction = IAuctionManager.EnglishAuction(
            address(this),
            auctionCurrency,
            msg.sender,
            auctionPaymentRecipient,
            auctionEndTime,
            0,
            true,
            IAuctionManager.AuctionState.LIVE_ON_CHAIN
        );

        IAuctionManager(auctionManagerAddress).createAuctionForNewEdition(auctionId, auction, editionId);

        return editionId;
    }

    /**
     * @notice See {IERC721EditionMint-mintOneToRecipient}
     */
    function mintOneToRecipient(uint256 editionId, address recipient)
        external
        onlyMinter
        nonReentrant
        returns (uint256)
    {
        require(_mintFrozen == 0, "Mint frozen");
        require(_editionExists(editionId), "Edition doesn't exist");

        return _mintEditionsToOne(editionId, recipient, 1);
    }

    /**
     * @notice See {IERC721EditionMint-mintAmountToRecipient}
     */
    function mintAmountToRecipient(
        uint256 editionId,
        address recipient,
        uint256 amount
    ) external onlyMinter nonReentrant returns (uint256) {
        require(_mintFrozen == 0, "Mint frozen");
        require(_editionExists(editionId), "Edition doesn't exist");

        return _mintEditionsToOne(editionId, recipient, amount);
    }

    /**
     * @notice See {IERC721EditionMint-mintOneToRecipients}
     */
    function mintOneToRecipients(uint256 editionId, address[] memory recipients)
        external
        onlyMinter
        nonReentrant
        returns (uint256)
    {
        require(_mintFrozen == 0, "Mint frozen");
        require(_editionExists(editionId), "Edition doesn't exist");
        return _mintEditions(editionId, recipients, 1);
    }

    /**
     * @notice See {IERC721EditionMint-mintAmountToRecipients}
     */
    function mintAmountToRecipients(
        uint256 editionId,
        address[] memory recipients,
        uint256 amount
    ) external onlyMinter nonReentrant returns (uint256) {
        require(_mintFrozen == 0, "Mint frozen");
        require(_editionExists(editionId), "Edition doesn't exist");
        return _mintEditions(editionId, recipients, amount);
    }

    /**
     * @notice See {IEditionCollection-getEditionDetails}
     */
    function getEditionDetails(uint256 editionId) external view returns (EditionDetails memory) {
        require(_editionExists(editionId), "Edition doesn't exist");
        return _getEditionDetails(editionId);
    }

    /**
     * @notice See {IEditionCollection-getEditionsDetailsAndUri}
     */
    function getEditionsDetailsAndUri(uint256[] calldata editionIds)
        external
        view
        returns (EditionDetails[] memory, string[] memory)
    {
        uint256 editionIdsLength = editionIds.length;
        EditionDetails[] memory editionsDetails = new EditionDetails[](editionIdsLength);
        string[] memory uris = new string[](editionIdsLength);

        for (uint256 i = 0; i < editionIdsLength; i++) {
            uris[i] = editionURI(editionIds[i]);
            editionsDetails[i] = _getEditionDetails(editionIds[i]);
        }

        return (editionsDetails, uris);
    }

    /**
     * @notice See {IEditionCollection-getEditionStartIds}
     */
    function getEditionStartIds() external view returns (uint256[] memory) {
        return editionStartId;
    }

    /**
     * @notice Total supply of NFTs on the Edition
     */
    function totalSupply() external view returns (uint256) {
        uint256 supply = 0;
        for (uint256 i = 0; i < editionCurrentSupply.length; i++) {
            supply += editionCurrentSupply[i];
        }
        return supply;
    }

    /**
     * @notice See {IERC721-transferFrom}. Overrides default behaviour to check associated tokenManager.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override nonReentrant onlyAllowedOperator(from) {
        ERC721Upgradeable.transferFrom(from, to, tokenId);

        address _manager = tokenManagerByTokenId(tokenId);
        if (_manager != address(0) && IERC165Upgradeable(_manager).supportsInterface(type(IPostTransfer).interfaceId)) {
            IPostTransfer(_manager).postTransferFrom(_msgSender(), from, to, tokenId);
        }
    }

    /**
     * @notice See {IERC721-safeTransferFrom}. Overrides default behaviour to check associated tokenManager.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override nonReentrant onlyAllowedOperator(from) {
        ERC721Upgradeable.safeTransferFrom(from, to, tokenId, data);

        address _manager = tokenManagerByTokenId(tokenId);
        if (_manager != address(0) && IERC165Upgradeable(_manager).supportsInterface(type(IPostTransfer).interfaceId)) {
            IPostTransfer(_manager).postSafeTransferFrom(_msgSender(), from, to, tokenId, data);
        }
    }

    /**
     * @notice See {IERC721-setApprovalForAll}.
     *         Overrides default behaviour to check MarketplaceFilterer allowed operators.
     */
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @notice See {IERC721-approve}.
     *         Overrides default behaviour to check MarketplaceFilterer allowed operators.
     */
    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /**
     * @notice See {IERC721-burn}. Overrides default behaviour to check associated tokenManager.
     */
    function burn(uint256 tokenId) public nonReentrant {
        uint256 editionId = getEditionId(tokenId);
        address _manager = tokenManager(editionId);

        if (_manager != address(0) && IERC165Upgradeable(_manager).supportsInterface(type(IPostBurn).interfaceId)) {
            address owner = ownerOf(tokenId);
            IPostBurn(_manager).postBurn(_msgSender(), owner, editionId);
        } else {
            // default to restricting burn to owner or operator if a valid TM isn't present
            require(_isApprovedOrOwner(_msgSender(), tokenId), "Not owner or operator");
        }

        _burn(tokenId);
    }

    /**
     * @notice Conforms to ERC-2981.
     * @param _tokenId Token id
     * @param _salePrice Sale price of token
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        public
        view
        virtual
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return ERC721Base.royaltyInfo(_getEditionId(_tokenId), _salePrice);
    }

    /**
     * @notice See {IEditionCollection-getEditionId}
     */
    function getEditionId(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Token doesn't exist");
        return _getEditionId(tokenId);
    }

    /**
     * @notice Used to get token manager of token id
     * @param tokenId ID of the token
     */
    function tokenManagerByTokenId(uint256 tokenId) public view returns (address) {
        return tokenManager(getEditionId(tokenId));
    }

    /**
     * @notice Get URI for given edition id
     * @param editionId edition id to get uri for
     * @return base64-encoded json metadata object
     */
    function editionURI(uint256 editionId) public view returns (string memory) {
        require(_editionExists(editionId), "Edition doesn't exist");
        return IEditionsMetadataRenderer(_metadataRendererAddress).editionURI(editionId);
    }

    /**
     * @notice Get URI for given token id
     * @param tokenId token id to get uri for
     * @return base64-encoded json metadata object
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token doesn't exist");
        return IMetadataRenderer(_metadataRendererAddress).tokenURI(tokenId);
    }

    /**
     * @notice See {IERC721Upgradeable-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165Upgradeable, ERC721Upgradeable)
        returns (bool)
    {
        return ERC721Upgradeable.supportsInterface(interfaceId);
    }

    /**
     * @notice Private function to mint without any access checks. Called by the public edition minting functions.
     * @param editionId Edition being minted on
     * @param recipients Recipients of newly minted tokens
     * @param _amount Amount minted to each recipient
     */
    function _mintEditions(
        uint256 editionId,
        address[] memory recipients,
        uint256 _amount
    ) internal returns (uint256) {
        uint256 recipientsLength = recipients.length;

        uint256 maxSupply = editionMaxSupply[editionId];
        uint256 currentSupply = editionCurrentSupply[editionId];
        uint256 startId = editionStartId[editionId];
        uint256 endAt = currentSupply + (recipientsLength * _amount);

        require(endAt <= maxSupply, "Sold out");

        for (uint256 i = 0; i < recipientsLength; i++) {
            for (uint256 j = 0; j < _amount; j++) {
                _mint(recipients[i], startId + currentSupply);
                currentSupply += 1;
            }
        }

        editionCurrentSupply[editionId] = currentSupply;

        emit EditionMintedToRecipients(editionId, recipients, _amount);

        return endAt;
    }

    /**
     * @notice Private function to mint without any access checks. Called by the public edition minting functions.
     * @param editionId Edition being minted on
     * @param recipient Recipient of newly minted token
     * @param _amount Amount minted to recipient
     */
    function _mintEditionsToOne(
        uint256 editionId,
        address recipient,
        uint256 _amount
    ) internal returns (uint256) {
        uint256 maxSupply = editionMaxSupply[editionId];
        uint256 currentSupply = editionCurrentSupply[editionId];
        uint256 startId = editionStartId[editionId];
        uint256 endAt = currentSupply + _amount;

        require(endAt <= maxSupply, "Sold out");

        for (uint256 j = 0; j < _amount; j++) {
            _mint(recipient, startId + currentSupply);
            currentSupply += 1;
        }

        editionCurrentSupply[editionId] = currentSupply;

        emit EditionMintedToOneRecipient(editionId, recipient, _amount);

        return endAt;
    }

    /**
     * @notice Get ID of a token's edition
     */
    function _getEditionId(uint256 tokenId) internal view returns (uint256) {
        uint256 editionId = 0;
        uint256[] memory tempEditionStartId = editionStartId; // cache
        uint256 tempEditionStartIdLength = tempEditionStartId.length; // cache
        for (uint256 i = 0; i < tempEditionStartIdLength; i += 1) {
            if (tokenId >= tempEditionStartId[i]) {
                editionId = i;
            }
        }
        return editionId;
    }

    /**
     * @notice Returns whether `editionId` exists.
     * @param editionId Id of edition being checked
     */
    function _editionExists(uint256 editionId) internal view returns (bool) {
        return editionId < editionCurrentSupply.length;
    }

    /**
     * @notice Used for meta-transactions
     */
    function _msgSender() internal view override(ERC721Base, ContextUpgradeable) returns (address sender) {
        return ERC2771ContextUpgradeable._msgSender();
    }

    /**
     * @notice Used for meta-transactions
     */
    function _msgData() internal view override(ERC721Base, ContextUpgradeable) returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }

    /**
     * @notice Initialize the contract
     * @param creator Creator/owner of contract
     * @param defaultRoyalty Default royalty object for contract (optional)
     * @param _defaultTokenManager Default token manager for contract (optional)
     * @param _contractURI Contract metadata
     * @param _name Name of token edition
     * @param _symbol Symbol of the token edition
     * @param metadataRendererAddress Contract returning metadata for each edition
     * @param trustedForwarder Trusted minimal forwarder
     * @param initialMinters Initial minters to register
     * @param useMarketplaceFiltererRegistry Denotes whether to use marketplace filterer registry
     */
    function _initialize(
        address creator,
        IRoyaltyManager.Royalty memory defaultRoyalty,
        address _defaultTokenManager,
        string memory _contractURI,
        string memory _name,
        string memory _symbol,
        address metadataRendererAddress,
        address trustedForwarder,
        address[] memory initialMinters,
        bool useMarketplaceFiltererRegistry
    ) private {
        __ERC721Base_initialize(creator, defaultRoyalty, _defaultTokenManager);
        __ERC721_init(_name, _symbol);
        __ERC2771ContextUpgradeable__init__(trustedForwarder);
        __MarketplaceFilterer__init__(useMarketplaceFiltererRegistry);
        _metadataRendererAddress = metadataRendererAddress;
        uint256 initialMintersLength = initialMinters.length;
        for (uint256 i = 0; i < initialMintersLength; i++) {
            _minters.add(initialMinters[i]);
        }
        nextTokenId = 1;
        contractURI = _contractURI;
    }

    /**
     * @notice Create edition
     * @param _editionInfo Info of the Edition
     * @param _editionSize Size of the Edition
     * @param _editionTokenManager Edition's token manager
     * @notice Used to create a new Edition within the Collection
     */
    function _createEdition(
        bytes memory _editionInfo,
        uint256 _editionSize,
        address _editionTokenManager
    ) private returns (uint256) {
        require(_editionSize > 0, "Edition size == 0");

        uint256 editionId = editionStartId.length;

        editionStartId.push(nextTokenId);
        editionMaxSupply.push(_editionSize);
        editionCurrentSupply.push(0);

        nextTokenId += _editionSize;

        IMetadataRenderer(_metadataRendererAddress).initializeMetadata(_editionInfo);

        if (_editionTokenManager != address(0)) {
            require(_isValidTokenManager(_editionTokenManager), "Invalid TM");
            _managers[editionId] = _editionTokenManager;
        }

        emit EditionCreated(editionId, _editionSize, _editionTokenManager);

        return editionId;
    }

    /**
     * @notice Get edition details
     * @param editionId Id of edition to get details for
     */
    function _getEditionDetails(uint256 editionId) private view returns (EditionDetails memory) {
        return
            EditionDetails(
                IEditionsMetadataRenderer(_metadataRendererAddress).editionInfo(address(this), editionId).name,
                editionMaxSupply[editionId],
                editionCurrentSupply[editionId],
                editionStartId[editionId]
            );
    }
}