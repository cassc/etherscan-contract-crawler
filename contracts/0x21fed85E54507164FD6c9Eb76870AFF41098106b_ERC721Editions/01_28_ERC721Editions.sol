// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./interfaces/IERC721Editions.sol";
import "./ERC721Base.sol";
import "../utils/Ownable.sol";
import "../metadata/interfaces/IMetadataRenderer.sol";
import "../metadata/interfaces/IEditionsMetadataRenderer.sol";
import "./interfaces/IEditionCollection.sol";

import "../tokenManager/interfaces/IPostTransfer.sol";
import "../utils/ERC721/ERC721Upgradeable.sol";
import "./interfaces/IERC721EditionMint.sol";

/**
 * @title ERC721 Editions
 * @author [email protected], [email protected]
 * @dev Multiple Editions Per Collection
 */
contract ERC721Editions is IEditionCollection, IERC721Editions, IERC721EditionMint, ERC721Base, ERC721Upgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * @dev Contract metadata
     */
    string public contractURI;

    /**
     * @dev Keeps track of next token ID
     */
    uint256 private _nextTokenId;

    /**
     * @dev Generates metadata for contract and token
     */
    address private _metadataRendererAddress;

    /**
     * @dev Tracks current supply of each edition, edition indexed
     */
    uint256[] public editionCurrentSupply;

    /**
     * @dev Tracks size of each edition, edition indexed
     */
    uint256[] public editionMaxSupply;

    /**
     * @dev Tracks start token id each edition, edition indexed
     */
    uint256[] public editionStartId;

    /**
     * @dev Emitted when edition is created
     * @param size Edition size
     * @param editionTokenManager Token manager for edition
     */
    event EditionCreated(uint256 indexed size, address indexed editionTokenManager);

    /**
     * @param creator Creator/owner of contract
     * @param defaultRoyalty Default royalty object for contract (optional)
     * @param _defaultTokenManager Default token manager for contract (optional)
     * @param _contractURI Contract metadata
     * @param _name Name of token edition
     * @param _symbol Symbol of the token edition
     * @param metadataRendererAddress Contract returning metadata for each edition
     * @param trustedForwarder Trusted minimal forwarder
     * @param initialMinter Initial minter to register
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
        address initialMinter
    ) external initializer nonReentrant {
        __ERC721Base_initialize(creator, defaultRoyalty, _defaultTokenManager);
        __ERC721_init(_name, _symbol);
        __ERC2771ContextUpgradeable__init__(trustedForwarder);
        _metadataRendererAddress = metadataRendererAddress;
        _minters.add(initialMinter);
        _nextTokenId = 1;
        contractURI = _contractURI;
    }

    /**
     * @param _editionInfo Info of the Edition
     * @param _editionSize Size of the Edition
     * @param _editionTokenManager Edition's token manager
     * @dev Used to create a new Edition within the Collection
     */
    function createEdition(
        bytes memory _editionInfo,
        uint256 _editionSize,
        address _editionTokenManager
    ) external onlyOwner nonReentrant returns (uint256) {
        require(_editionSize > 0, "Edition size == 0");

        uint256 editionId = editionStartId.length;

        editionStartId.push(_nextTokenId);
        editionMaxSupply.push(_editionSize);
        editionCurrentSupply.push(0);

        _nextTokenId += _editionSize;

        IMetadataRenderer(_metadataRendererAddress).initializeMetadata(_editionInfo);

        if (_editionTokenManager != address(0)) {
            _managers[editionId] = _editionTokenManager;
        }

        emit EditionCreated(_editionSize, _editionTokenManager);

        return editionId;
    }

    /**
     * @dev See {IERC721EditionMint-mintOneToRecipient}
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
     * @dev See {IERC721EditionMint-mintAmountToRecipient}
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
     * @dev See {IERC721EditionMint-mintOneToRecipients}
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
     * @dev See {IERC721EditionMint-mintAmountToRecipients}
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
     * @dev See {IEditionCollection-getEditionDetails}
     */
    function getEditionDetails(uint256 editionId) external view returns (EditionDetails memory) {
        require(_editionExists(editionId), "Edition doesn't exist");
        return _getEditionDetails(editionId);
    }

    /**
     * @dev See {IEditionCollection-getEditionsDetailsAndUri}
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
     * @dev See {IEditionCollection-getEditionStartIds}
     */
    function getEditionStartIds() external view returns (uint256[] memory) {
        return editionStartId;
    }

    /**
     * @dev See {IERC721-transferFrom}. Overrides default behaviour to check associated tokenManager.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override nonReentrant {
        ERC721Upgradeable.transferFrom(from, to, tokenId);

        address _manager = tokenManagerByTokenId(tokenId);
        if (_manager != address(0) && IERC165Upgradeable(_manager).supportsInterface(type(IPostTransfer).interfaceId)) {
            IPostTransfer(_manager).postTransferFrom(_msgSender(), from, to, tokenId);
        }
    }

    /**
     * @dev See {IERC721-safeTransferFrom}. Overrides default behaviour to check associated tokenManager.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override nonReentrant {
        ERC721Upgradeable.safeTransferFrom(from, to, tokenId, data);

        address _manager = tokenManagerByTokenId(tokenId);
        if (_manager != address(0) && IERC165Upgradeable(_manager).supportsInterface(type(IPostTransfer).interfaceId)) {
            IPostTransfer(_manager).postSafeTransferFrom(_msgSender(), from, to, tokenId, data);
        }
    }

    /**
     * @dev Conforms to ERC-2981.
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
        return ERC721Base.royaltyInfo(getEditionId(_tokenId), _salePrice);
    }

    /**
     * @dev See {IEditionCollection-getEditionId}
     */
    function getEditionId(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Token doesn't exist");
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
     * @dev Used to get token manager of token id
     * @param tokenId ID of the token
     */
    function tokenManagerByTokenId(uint256 tokenId) public view returns (address) {
        return tokenManager(getEditionId(tokenId));
    }

    /**
     * @dev Get URI for given edition id
     * @param editionId edition id to get uri for
     * @return base64-encoded json metadata object
     */
    function editionURI(uint256 editionId) public view returns (string memory) {
        require(_editionExists(editionId), "Edition doesn't exist");
        return IEditionsMetadataRenderer(_metadataRendererAddress).editionURI(editionId);
    }

    /**
     * @dev Get URI for given token id
     * @param tokenId token id to get uri for
     * @return base64-encoded json metadata object
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token doesn't exist");
        return IMetadataRenderer(_metadataRendererAddress).tokenURI(tokenId);
    }

    /**
     * @dev See {IERC721Upgradeable-supportsInterface}.
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
     * @dev Private function to mint without any access checks. Called by the public edition minting functions.
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
        return endAt;
    }

    /**
     * @dev Private function to mint without any access checks. Called by the public edition minting functions.
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
        return endAt;
    }

    /**
     * @dev Returns whether `editionId` exists.
     * @param editionId Id of edition being checked
     */
    function _editionExists(uint256 editionId) internal view returns (bool) {
        return editionId < editionCurrentSupply.length;
    }

    /**
     * @dev Used for meta-transactions
     */
    function _msgSender() internal view override(ERC721Base, ContextUpgradeable) returns (address sender) {
        return ERC2771ContextUpgradeable._msgSender();
    }

    /**
     * @dev Used for meta-transactions
     */
    function _msgData() internal view override(ERC721Base, ContextUpgradeable) returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }

    /**
     * @dev Get edition details
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