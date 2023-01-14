// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "./SerialERC2981Upgradeable.sol";
import "./RolesUpgradeable.sol";


contract NiioERC721SerialV1 is
Initializable,
PausableUpgradeable,
AccessControlUpgradeable,
OwnableUpgradeable,
ERC721BurnableUpgradeable,
UUPSUpgradeable,
SerialERC2981Upgradeable,
DefaultOperatorFiltererUpgradeable,
RolesUpgradeable {

    mapping(uint256 => string) internal _tokensMetadataHashes; //tokenId -> uri hash
    mapping(uint256 => SeriesInfo) internal _seriesInfo; //seriesId -> series SeriesInfo
    string internal _contractURI;

    struct SeriesInfo {
        string metadataHash;
        uint256 maxEditions;
        uint256 mintedEditions;
    }

    function initialize(
        address admin,
        address superAdmin,
        string memory contractLevelURI,
        string memory tokenName,
        string memory tokenSymbol,
        address royaltyReceiver,
        uint96 royaltyFeesInBips)
    public
    initializer {
        __ERC721_init(tokenName, tokenSymbol);
        __Pausable_init();
        __AccessControl_init();
        __ERC721Burnable_init();
        __UUPSUpgradeable_init();
        __ERC2981_init();
        __DefaultOperatorFilterer_init();
        __Roles_init();

        _grantRole(ADMIN_ROLE, admin);
        _grantRole(SUPER_ADMIN_ROLE, superAdmin);
        //superAdmin will be able to grant or revoke all roles
        _grantRole(DEFAULT_ADMIN_ROLE, superAdmin);
        _transferOwnership(superAdmin);
        _contractURI = contractLevelURI;

        super._setDefaultRoyalty(royaltyReceiver, royaltyFeesInBips);
    }

    // Modifiers //

    modifier seriesNotExist(uint256 seriesId) {
        require(_seriesInfo[seriesId].maxEditions == 0, "Series already exists");
        _;
    }

    modifier seriesExist(uint256 seriesId) {
        require(_seriesInfo[seriesId].maxEditions > 0, "Series not exist");
        _;
    }

    modifier validEdition(uint256 seriesId, uint256 tokenId, uint256 minTokenId, uint256 maxTokenId) {
        SeriesInfo memory seriesInfo = _seriesInfo[seriesId];
        require(seriesInfo.maxEditions > 0, "Series not exist");
        require(seriesInfo.mintedEditions < seriesInfo.maxEditions, "Series fully minted");
        require(tokenId > minTokenId && tokenId < maxTokenId, "TokenId not belong to series");
        _;
    }

    modifier validNumberOfEditions(uint256 maxEditions, uint256 numberOfMintedEditions) {
        require(numberOfMintedEditions > 0, "Invalid number of minted editions");
        require(maxEditions >= numberOfMintedEditions, "Minted editions must be less than maxEditions");
        _;
    }

    // Functions //

    /**
     * @notice Creating a new series. The given `tokensIds` are transferred to `creator`.
     */
    function mintNewSeries(uint256 seriesId, uint256 maxEditions, uint256[] memory tokensIds, string[] memory tokensMetadataHashes, string memory seriesMetadataHash, address creator)
    public
    onlyRole(ADMIN_ROLE)
    seriesNotExist(seriesId)
    validNumberOfEditions(maxEditions, tokensIds.length) {
        require(tokensIds.length == tokensMetadataHashes.length, "tokensIds must have the same length as tokensMetadataHashes");
        (uint256 minTokenId, uint256 maxTokenId) = getTokensRange(seriesId);
        _seriesInfo[seriesId] = SeriesInfo(seriesMetadataHash, maxEditions, tokensIds.length);
        for (uint i = 0; i < tokensIds.length; i++) {
            require(tokensIds[i] > minTokenId && tokensIds[i] < maxTokenId, "TokenId not belong to series");
            _safeMint(creator, tokensIds[i]);
            _tokensMetadataHashes[tokensIds[i]] = tokensMetadataHashes[i];
        }
    }

    /**
     * @notice Creating a new series and transferring `tokensToTransfer` from `creator` to the corresponding buyer in the `buyers` list.
     */
    function mintNewSeriesAndTransfer(uint256 seriesId, uint256 maxEditions, uint256[] calldata tokensIds, string[] calldata tokensMetadataHashes, string memory seriesMetadataHash, address creator, address[] memory buyers, uint256[] calldata tokensToTransfer)
    external {
        require(buyers.length == tokensToTransfer.length, "buyers must have the same length as tokensToTransfer");
        mintNewSeries(seriesId, maxEditions, tokensIds, tokensMetadataHashes, seriesMetadataHash, creator);
        for (uint i = 0; i < tokensToTransfer.length; i++) {
            safeTransferFrom(creator, buyers[i], tokensToTransfer[i]);
        }
    }

    /**
     * @notice Creating a new series and transferring `tokensToTransfer` from `creator` to `gallery` and from `gallery` to the corresponding buyer in the `buyers` list.
     */
    function mintNewSeriesAndTransferByGallery(uint256 seriesId, uint256 maxEditions, uint256[] calldata tokensIds, string[] calldata tokensMetadataHashes, string memory seriesMetadataHash, address creator, address gallery, address[] memory buyers, uint256[] memory tokensToTransfer)
    external {
        require(buyers.length == tokensToTransfer.length, "buyers must have the same length as tokensToTransfer");
        mintNewSeries(seriesId, maxEditions, tokensIds, tokensMetadataHashes, seriesMetadataHash, creator);
        for (uint i = 0; i < tokensToTransfer.length; i++) {
            safeTransferFrom(creator, gallery, tokensToTransfer[i]);
            safeTransferFrom(gallery, buyers[i], tokensToTransfer[i]);
        }
    }


    /**
     * @notice Adding multiple editions to an existing series (which is assigned to `creator).
     */
    function mintEditions(uint256 seriesId, uint256[] memory tokensIds, string[] memory tokensMetadataHashes, address creator)
    public
    onlyRole(ADMIN_ROLE) {
        require(tokensIds.length == tokensMetadataHashes.length, "tokensIds must have the same length as tokensMetadataHashes");
        (uint256 minTokenId, uint256 maxTokenId) = getTokensRange(seriesId);
        for (uint i = 0; i < tokensIds.length; i++) {
            mintEdition(seriesId, tokensIds[i], tokensMetadataHashes[i], creator, minTokenId, maxTokenId);
        }
    }

    /**
     * @notice Adding multiple editions to an existing series and transferring `tokensToTransfer` from `creator` to the corresponding buyer in the `buyers` list.
     */
    function mintEditionsAndTransfer(uint256 seriesId, uint256[] calldata tokensIds, string[] calldata tokensMetadataHashes, address creator, address[] memory buyers, uint256[] calldata tokensToTransfer)
    external {
        require(tokensToTransfer.length == buyers.length, "tokensToTransfer must have the same length as buyers");
        mintEditions(seriesId, tokensIds, tokensMetadataHashes, creator);
        for (uint i = 0; i < tokensToTransfer.length; i++) {
            safeTransferFrom(creator, buyers[i], tokensToTransfer[i]);
        }
    }

    /**
     * @notice Adding multiple editions to an existing series and transferring `tokensToTransfer` from `creator` to the corresponding buyer in the `buyers` list.
     */
    function mintEditionsAndTransferByGallery(uint256 seriesId, uint256[] calldata tokensIds, string[] calldata tokensMetadataHashes, address creator, address gallery, address[] memory buyers, uint256[] calldata tokensToTransfer)
    external {
        require(tokensToTransfer.length == buyers.length, "tokensToTransfer must have the same length as buyers");
        mintEditions(seriesId, tokensIds, tokensMetadataHashes, creator);
        for (uint i = 0; i < tokensToTransfer.length; i++) {
            safeTransferFrom(creator, gallery, tokensToTransfer[i]);
            safeTransferFrom(gallery, buyers[i], tokensToTransfer[i]);
        }
    }

    function mintEdition(uint256 seriesId, uint256 tokenId, string memory tokenMetadataHash, address creator, uint256 minTokenId, uint256 maxTokenId)
    internal
    validEdition(seriesId, tokenId, minTokenId, maxTokenId) {
        _safeMint(creator, tokenId);
        _tokensMetadataHashes[tokenId] = tokenMetadataHash;
        _seriesInfo[seriesId].mintedEditions++;
    }

    /**
     * @notice Transferring the given editions (all must be owned by `owner`) to `recipient`.
     */
    function transferMultipleEditions(uint256[] calldata tokensIds, address owner, address recipient)
    external
    onlyRole(ADMIN_ROLE) {
        for (uint i = 0; i < tokensIds.length; i++) {
            safeTransferFrom(owner, recipient, tokensIds[i]);
        }
    }

    function getTokenSeriesInfo(uint256 tokenId)
    public
    view
    returns (SeriesInfo memory) {
        uint256 seriesId = getTokenSeriesId(tokenId);
        return _seriesInfo[seriesId];
    }

    function getSeriesInfo(uint256 seriesId)
    public
    view
    returns (SeriesInfo memory) {
        return _seriesInfo[seriesId];
    }

    /**
     * @dev Given a seriesId, a token belonging to this series must be in the range of minTokenId < tokenId < maxTokenId
     */
    function getTokensRange(uint256 seriesId)
    internal
    pure
    returns (uint256 minTokenId, uint256 maxTokenId) {
        minTokenId = seriesId * SERIES_FACTOR;
        maxTokenId = (seriesId + 1) * SERIES_FACTOR;
        return (minTokenId, maxTokenId);
    }

    function updateSeriesMetadataHash(uint256 seriesId, string memory seriesMetadataHash)
    external
    onlyRole(ADMIN_ROLE)
    whenNotPaused
    seriesExist(seriesId) {
        _seriesInfo[seriesId].metadataHash = seriesMetadataHash;
    }

    function updateSeriesMaxEditions(uint256 seriesId, uint256 maxEditions)
    external
    onlyRole(ADMIN_ROLE)
    whenNotPaused
    seriesExist(seriesId) {
        require(maxEditions >= _seriesInfo[seriesId].mintedEditions, "Value is lower then minted");
        _seriesInfo[seriesId].maxEditions = maxEditions;
    }

    /**
     * @notice Burns the given tokens of the given series.
     * The given tokens must all belong to the given series.
     */
    function burnTokens(uint256 seriesId, uint256[] calldata tokensIds)
    external
    onlyRole(SUPER_ADMIN_ROLE) {
        (uint256 minTokenId, uint256 maxTokenId) = getTokensRange(seriesId);
        for (uint i = 0; i < tokensIds.length; i++) {
            require(tokensIds[i] > minTokenId && tokensIds[i] < maxTokenId, "TokenId not belong to series");
            _burn(tokensIds[i]);
        }
        _seriesInfo[seriesId].mintedEditions -= tokensIds.length;
        if (_seriesInfo[seriesId].mintedEditions == 0) {
            delete _seriesInfo[seriesId];
            super._resetSeriesRoyalty(seriesId);
        }
    }

    /**
     * @notice Burns the given series along with all of its tokens.
     * This function may result in high gas consumption.
     */
    function burnSeriesAndAllTokens(uint256 seriesId)
    external
    onlyRole(SUPER_ADMIN_ROLE) {
        uint256 numberOfMintedEditions = _seriesInfo[seriesId].mintedEditions;
        delete _seriesInfo[seriesId];
        super._resetSeriesRoyalty(seriesId);
        burnTokensOfSeries(seriesId, numberOfMintedEditions);
    }

    function burnTokensOfSeries(uint256 seriesId, uint256 numberOfMintedEditions)
    internal {
        uint256 start = seriesId * SERIES_FACTOR;
        uint256 end = start + SERIES_FACTOR;
        uint256 burned = 0;
        uint256 i = 1;
        while (i < end && burned < numberOfMintedEditions) {
            uint256 tokenId = start + i;
            if (_exists(tokenId)) {
                _burn(tokenId);
                burned++;
            }
            i++;
        }
    }

    /**
     * @inheritdoc ERC721BurnableUpgradeable
     */
    function burn(uint256 tokenId)
    public
    virtual
    override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner nor approved");
        uint256 seriesId = getTokenSeriesId(tokenId);
        _seriesInfo[seriesId].mintedEditions--;
        _burn(tokenId);
    }

    function _burn(uint256 tokenId)
    internal
    virtual
    override
    whenNotPaused {
        delete _tokensMetadataHashes[tokenId];
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
    internal
    whenNotPaused
    override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        string memory baseURI = _baseURI();
        string memory metadataHash = _tokensMetadataHashes[tokenId];
        return string(abi.encodePacked(baseURI, metadataHash));
    }

    function _baseURI()
    internal
    pure
    override
    returns (string memory) {
        return "ipfs://";
    }

    function pause()
    public
    onlyRole(SUPER_ADMIN_ROLE) {
        _pause();
    }

    function unpause()
    public
    onlyRole(SUPER_ADMIN_ROLE) {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    whenNotPaused
    onlyRole(SUPER_ADMIN_ROLE)
    override
    {}

    function isApprovedForAll(address owner, address operator)
    public
    view
    override
    returns (bool) {
        // Whitelist Niio admin
        if (hasRole(ADMIN_ROLE, operator)) {
            return true;
        }
        // otherwise, use the default ERC721.isApprovedForAll()
        return super.isApprovedForAll(owner, operator);
    }

    function setContractURI(string calldata uriToSet)
    external
    whenNotPaused
    onlyRole(SUPER_ADMIN_ROLE) {
        _contractURI = uriToSet;
    }

    /**
     * @dev For open-sea integration
     */
    function contractURI()
    public
    view
    returns (string memory) {
        return _contractURI;
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721Upgradeable, AccessControlUpgradeable, SerialERC2981Upgradeable)
    returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function transferOwnership(address newOwner)
    public
    virtual
    override
    whenNotPaused
    onlyRole(SUPER_ADMIN_ROLE) {
        require(newOwner != address(0), "New owner is the zero address");
        super._transferOwnership(newOwner);
    }

    /* Royalties */

    function setDefaultRoyalty(address receiver, uint96 royaltyFeesInBips)
    public
    whenNotPaused
    onlyRole(SUPER_ADMIN_ROLE) {
        super._setDefaultRoyalty(receiver, royaltyFeesInBips);
    }

    /**
     * @notice Set a custom royalty for the given series
     */
    function setSeriesRoyalty(uint256 seriesId, address receiver, uint96 royaltyFeesInBips)
    public
    whenNotPaused
    onlyRole(ADMIN_ROLE) {
        super._setSeriesRoyalty(seriesId, receiver, royaltyFeesInBips);
    }

    function resetSeriesRoyalty(uint256 seriesId)
    public
    whenNotPaused
    onlyRole(ADMIN_ROLE) {
        super._resetSeriesRoyalty(seriesId);
    }

    /* Opensea creator fee enforcement */

    function setApprovalForAll(address operator, bool approved)
    public
    override
    onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
    public
    override
    onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
    public
    override
    onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
    public
    override
    onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    override
    onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}