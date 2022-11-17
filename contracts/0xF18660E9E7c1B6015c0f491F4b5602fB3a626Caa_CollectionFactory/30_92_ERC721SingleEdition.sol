// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "../utils/Ownable.sol";
import "../metadata/interfaces/IMetadataRenderer.sol";
import "../metadata/interfaces/IEditionsMetadataRenderer.sol";
import "./interfaces/IEditionCollection.sol";
import "./ERC721MinimizedBase.sol";
import "../tokenManager/interfaces/IPostTransfer.sol";
import "../utils/ERC721/ERC721Upgradeable.sol";
import "./interfaces/IERC721EditionMint.sol";

/**
 * @title ERC721 Single Edition
 * @author [email protected], [email protected]
 * @dev Single Edition Per Collection
 */
contract ERC721SingleEdition is IERC721EditionMint, IEditionCollection, ERC721MinimizedBase, ERC721Upgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * @dev Contract metadata
     */
    string public contractURI;

    /**
     * @dev Keeps track of current token ID in supply
     */
    uint256 private _currentId;

    /**
     * @dev Generates metadata for contract and token
     */
    address private _metadataRendererAddress;

    /**
     * @notice Total size of edition that can be minted
     */
    uint256 public size;

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
     * @param _editionInfo Edition info
     * @param _size Edition size
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
        bytes memory _editionInfo,
        uint256 _size,
        address metadataRendererAddress,
        address trustedForwarder,
        address initialMinter
    ) external initializer nonReentrant {
        __ERC721MinimizedBase_initialize(creator, defaultRoyalty, _defaultTokenManager);
        __ERC721_init(_name, _symbol);
        __ERC2771ContextUpgradeable__init__(trustedForwarder);
        size = _size;
        _metadataRendererAddress = metadataRendererAddress;
        IMetadataRenderer(metadataRendererAddress).initializeMetadata(_editionInfo);
        _minters.add(initialMinter);
        _currentId = 1;
        contractURI = _contractURI;

        emit EditionCreated(_size, _defaultTokenManager);
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

        return _mintEditionsToOne(recipient, 1);
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

        return _mintEditionsToOne(recipient, amount);
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
        return _mintEditions(recipients, 1);
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
        return _mintEditions(recipients, amount);
    }

    /**
     * @dev See {IEditionCollection-getEditionId}
     */
    function getEditionId(uint256 tokenId) external view returns (uint256) {
        require(_exists(tokenId), "Token Id doesn't exist");
        return 0;
    }

    /**
     * @dev See {IEditionCollection-getEditionDetails}
     */
    function getEditionDetails(uint256 editionId) external view returns (EditionDetails memory) {
        require(_editionExists(editionId), "Edition doesn't exist");
        return _getEditionDetails();
    }

    /**
     * @dev See {IEditionCollection-getEditionsDetailsAndUri}
     */
    function getEditionsDetailsAndUri(uint256[] calldata editionIds)
        external
        view
        returns (EditionDetails[] memory, string[] memory)
    {
        require(editionIds.length == 1, "One possible edition id");
        EditionDetails[] memory editionsDetails = new EditionDetails[](1);
        string[] memory uris = new string[](1);

        // expected to be 0, validated in editionURI call
        uint256 editionId = editionIds[0];

        uris[0] = editionURI(editionId);
        editionsDetails[0] = _getEditionDetails();

        return (editionsDetails, uris);
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

        address _manager = defaultManager;
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

        address _manager = defaultManager;
        if (_manager != address(0) && IERC165Upgradeable(_manager).supportsInterface(type(IPostTransfer).interfaceId)) {
            IPostTransfer(_manager).postSafeTransferFrom(_msgSender(), from, to, tokenId, data);
        }
    }

    /**
     * @dev Conforms to ERC-2981.
     * @param // Token id
     * @param _salePrice Sale price of token
     */
    function royaltyInfo(
        uint256, /* _tokenId */
        uint256 _salePrice
    ) public view virtual override returns (address receiver, uint256 royaltyAmount) {
        return ERC721MinimizedBase.royaltyInfo(0, _salePrice);
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
        require(_exists(tokenId), "No token");
        return IMetadataRenderer(_metadataRendererAddress).tokenURI(tokenId);
    }

    /**
     * @dev Used to get token manager of token id
     * @param tokenId ID of the token
     */
    function tokenManagerByTokenId(uint256 tokenId) public view returns (address) {
        return tokenManager(tokenId);
    }

    /**
     * @dev Private function to mint without any access checks. Called by the public edition minting functions.
     * @param recipients Recipients of newly minted tokens
     * @param _amount Amount minted to each recipient
     */
    function _mintEditions(address[] memory recipients, uint256 _amount) internal returns (uint256) {
        uint256 recipientsLength = recipients.length;

        uint256 tempCurrent = _currentId;
        uint256 endAt = tempCurrent + (recipientsLength * _amount) - 1;

        require(size == 0 || endAt <= size, "Sold out");

        for (uint256 i = 0; i < recipientsLength; i++) {
            for (uint256 j = 0; j < _amount; j++) {
                _mint(recipients[i], tempCurrent);
                tempCurrent += 1;
            }
        }
        _currentId = tempCurrent;
        return _currentId;
    }

    /**
     * @dev Private function to mint without any access checks. Called by the public edition minting functions.
     * @param recipient Recipient of newly minted token
     * @param _amount Amount minted to recipient
     */
    function _mintEditionsToOne(address recipient, uint256 _amount) internal returns (uint256) {
        uint256 tempCurrent = _currentId;
        uint256 endAt = tempCurrent + _amount - 1;

        require(size == 0 || endAt <= size, "Sold out");

        for (uint256 j = 0; j < _amount; j++) {
            _mint(recipient, tempCurrent);
            tempCurrent += 1;
        }
        _currentId = tempCurrent;
        return _currentId;
    }

    /**
     * @dev Used for meta-transactions
     */
    function _msgSender() internal view override(ERC721MinimizedBase, ContextUpgradeable) returns (address sender) {
        return ERC2771ContextUpgradeable._msgSender();
    }

    /**
     * @dev Used for meta-transactions
     */
    function _msgData() internal view override(ERC721MinimizedBase, ContextUpgradeable) returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }

    /**
     * @dev Returns whether `editionId` exists.
     */
    function _editionExists(uint256 editionId) internal pure returns (bool) {
        return editionId == 0;
    }

    /**
     * @dev Get edition details
     */
    function _getEditionDetails() private view returns (EditionDetails memory) {
        return EditionDetails(this.name(), size, _currentId - 1, 1);
    }
}