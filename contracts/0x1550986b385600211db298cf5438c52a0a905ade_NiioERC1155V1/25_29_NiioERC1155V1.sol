// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "./RolesUpgradeable.sol";

contract NiioERC1155V1 is
Initializable,
AccessControlUpgradeable,
OwnableUpgradeable,
ERC1155Upgradeable,
ERC1155BurnableUpgradeable,
ERC1155PausableUpgradeable,
UUPSUpgradeable,
ERC2981Upgradeable,
DefaultOperatorFiltererUpgradeable,
RolesUpgradeable {

    mapping(uint256 => ArtworkInfo) internal _artworksInfo; //ArtworkId -> ArtworkInfo
    string internal _contractURI;
    string public name;
    string public symbol;

    struct ArtworkInfo {
        string metadataHash;
        uint256 maxEditions;
        uint256 mintedEditions;
    }

    struct ArtworksEditions {
        uint256[] artworksIds;
        uint256[] amounts;
    }

    struct TransferDescriptor {
        address buyer;
        ArtworksEditions artworksToTransfer;
    }

    struct GalleryTransferDescriptor {
        TransferDescriptor transferDescriptor;
        address gallery;
    }

    struct BurnDescriptor {
        address owner;
        ArtworksEditions artworksToBurn;
    }

    function initialize(
        address admin,
        address superAdmin,
        string memory contractLevelURI,
        address royaltyReceiver,
        uint96 royaltyFeesInBips)
    public
    initializer {
        __AccessControl_init();
        __ERC1155_init("");
        __ERC1155Burnable_init();
        __ERC1155Pausable_init();
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
        name = "Niio Multiple";
        symbol = "NIIOM";
        super._setDefaultRoyalty(royaltyReceiver, royaltyFeesInBips);
    }

    // Modifiers //

    modifier artworkExist(uint256 artworkId) {
        require(_artworksInfo[artworkId].maxEditions > 0, "Artwork not exist");
        _;
    }

    // Functions //

    function mintNewArtworks(address creator, uint256[] memory artworksIds, uint256[] memory amounts, uint256[] memory maxEditions, string[] memory metadataHashes)
    public
    onlyRole(ADMIN_ROLE) {
        require(artworksIds.length == maxEditions.length &&
            artworksIds.length == metadataHashes.length,
            "artworksIds, maxEditions, metadataHashes length mismatch");
        artworksIds.length > 1 ?
        _mintBatch(creator, artworksIds, amounts, "") : //batch minting
        _mint(creator, artworksIds[0], amounts[0], ""); //single minting
        for (uint i = 0; i < artworksIds.length; i++) {
            require(_artworksInfo[artworksIds[i]].maxEditions == 0, "Artwork already exist");
            require(amounts[i] > 0 && maxEditions[i] >= amounts[i], "Exceeds the max");
            _artworksInfo[artworksIds[i]] = ArtworkInfo(metadataHashes[i], maxEditions[i], amounts[i]);
        }
    }

    function mintNewArtworksAndTransfer(address creator, uint256[] calldata artworksIds, uint256[] calldata amounts, uint256[] calldata maxEditions, string[] calldata metadataHashes, TransferDescriptor[] calldata transferDescriptors)
    external {
        mintNewArtworks(creator, artworksIds, amounts, maxEditions, metadataHashes);
        executeTransfers(creator, transferDescriptors);
    }

    function mintNewArtworksAndTransferByGallery(address creator, uint256[] calldata artworksIds, uint256[] calldata amounts, uint256[] calldata maxEditions, string[] calldata metadataHashes, GalleryTransferDescriptor[] calldata galleryTransferDescriptors)
    external {
        mintNewArtworks(creator, artworksIds, amounts, maxEditions, metadataHashes);
        executeTransfersViaGallery(creator, galleryTransferDescriptors);
    }

    /**
     * @notice Adding editions to existing artworks (which are assigned to `creator).
     */
    function mintArtworkEditions(address creator, uint256[] memory artworksIds, uint256[] memory amounts)
    public
    onlyRole(ADMIN_ROLE) {
        for (uint i = 0; i < artworksIds.length; i++) {
            require(_artworksInfo[artworksIds[i]].maxEditions > 0, "Artwork not exist");
            require(_artworksInfo[artworksIds[i]].mintedEditions + amounts[i] <= _artworksInfo[artworksIds[i]].maxEditions, "Exceeds max editions");
        }
        artworksIds.length > 1 ?
        _mintBatch(creator, artworksIds, amounts, "") : //batch minting
        _mint(creator, artworksIds[0], amounts[0], ""); //single minting
    }

    /**
     * @notice Adding editions to existing artworks and transferring artworks based on `transferDescriptors`
     */
    function mintArtworkEditionsAndTransfer(address creator, uint256[] calldata artworksIds, uint256[] calldata amounts, TransferDescriptor[] calldata transferDescriptors)
    external {
        mintArtworkEditions(creator, artworksIds, amounts);
        executeTransfers(creator, transferDescriptors);
    }

    /**
     * @notice Adding editions to existing artworks and transferring artworks based on `galleryTransferDescriptors`
     */
    function mintArtworkEditionsAndTransferByGallery(address creator, uint256[] calldata artworksIds, uint256[] calldata amounts, GalleryTransferDescriptor[] calldata galleryTransferDescriptors)
    external {
        mintArtworkEditions(creator, artworksIds, amounts);
        executeTransfersViaGallery(creator, galleryTransferDescriptors);
    }

    function executeTransfers(address creator, TransferDescriptor[] calldata transferDescriptors)
    internal {
        for (uint i = 0; i < transferDescriptors.length; i++) {
            transferDescriptors[i].artworksToTransfer.artworksIds.length > 1 ?
            safeBatchTransferFrom(creator, transferDescriptors[i].buyer, transferDescriptors[i].artworksToTransfer.artworksIds, transferDescriptors[i].artworksToTransfer.amounts, "") : //batch transfer
            safeTransferFrom(creator, transferDescriptors[i].buyer, transferDescriptors[i].artworksToTransfer.artworksIds[0], transferDescriptors[i].artworksToTransfer.amounts[0], ""); //single transfer
        }
    }

    function executeTransfersViaGallery(address creator, GalleryTransferDescriptor[] calldata galleryTransferDescriptors)
    internal {
        for (uint i = 0; i < galleryTransferDescriptors.length; i++) {
            TransferDescriptor memory transferDescriptor = galleryTransferDescriptors[i].transferDescriptor;
            if (transferDescriptor.artworksToTransfer.artworksIds.length > 1) {//batch transfer
                safeBatchTransferFrom(creator, galleryTransferDescriptors[i].gallery, transferDescriptor.artworksToTransfer.artworksIds, transferDescriptor.artworksToTransfer.amounts, "");
                safeBatchTransferFrom(galleryTransferDescriptors[i].gallery, transferDescriptor.buyer, transferDescriptor.artworksToTransfer.artworksIds, transferDescriptor.artworksToTransfer.amounts, "");
            } else {//single transfer
                safeTransferFrom(creator, galleryTransferDescriptors[i].gallery, transferDescriptor.artworksToTransfer.artworksIds[0], transferDescriptor.artworksToTransfer.amounts[0], "");
                safeTransferFrom(galleryTransferDescriptors[i].gallery, transferDescriptor.buyer, transferDescriptor.artworksToTransfer.artworksIds[0], transferDescriptor.artworksToTransfer.amounts[0], "");
            }
        }
    }

    function updateArtworkMetadataHash(uint256 artworkId, string memory artworkMetadataHash)
    external
    onlyRole(ADMIN_ROLE)
    whenNotPaused
    artworkExist(artworkId) {
        _artworksInfo[artworkId].metadataHash = artworkMetadataHash;
    }

    function updateArtworkMaxEditions(uint256 artworkId, uint256 maxEditions)
    external
    onlyRole(ADMIN_ROLE)
    whenNotPaused
    artworkExist(artworkId) {
        require(maxEditions >= _artworksInfo[artworkId].mintedEditions, "Value is lower then minted");
        _artworksInfo[artworkId].maxEditions = maxEditions;
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    )
    internal
    virtual
    override
    whenNotPaused {
        super._burn(from, id, amount);
    }

    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal
    virtual
    override
    whenNotPaused {
        super._burnBatch(from, ids, amounts);
    }

    function burnFromMultipleOwners(BurnDescriptor[] calldata burnDescriptors)
    external
    onlyRole(ADMIN_ROLE) {
        for (uint256 i = 0; i < burnDescriptors.length; ++i) {
            BurnDescriptor memory burnDescriptor = burnDescriptors[i];
            burnDescriptor.artworksToBurn.artworksIds.length > 1 ?
            burnBatch(burnDescriptor.owner, burnDescriptor.artworksToBurn.artworksIds, burnDescriptor.artworksToBurn.amounts) :
            burn(burnDescriptor.owner, burnDescriptor.artworksToBurn.artworksIds[0], burnDescriptor.artworksToBurn.amounts[0]);
        }
    }

    function uri(uint256 artworkId)
    public
    view
    virtual
    override
    returns (string memory) {
        string memory metadataHash = _artworksInfo[artworkId].metadataHash;
        return string(
            abi.encodePacked("ipfs://", metadataHash));
    }

    /**
     * @dev Total amount of minted tokens for a given artworkId.
     */
    function totalSupply(uint256 artworkId)
    public
    view
    virtual
    returns (uint256) {
        return _artworksInfo[artworkId].mintedEditions;
    }

    function getArtworkInfo(uint256 artworkId)
    public
    view
    returns (ArtworkInfo memory) {
        return _artworksInfo[artworkId];
    }

    function deleteArtworkInfo(uint256 artworkId)
    external
    whenNotPaused
    artworkExist(artworkId)
    onlyRole(SUPER_ADMIN_ROLE) {
        require(_artworksInfo[artworkId].mintedEditions == 0, "Cannot delete artwork with existing tokens");
        delete _artworksInfo[artworkId];
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

    function isApprovedForAll(address owner, address operator)
    public
    view
    override
    returns (bool) {
        // Whitelist Niio admin
        if (hasRole(ADMIN_ROLE, operator)) {
            return true;
        }
        // otherwise, use the default ERC1155.isApprovedForAll()
        return ERC1155Upgradeable.isApprovedForAll(owner, operator);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory artworksIds, uint256[] memory amounts, bytes memory data)
    internal
    override(ERC1155Upgradeable, ERC1155PausableUpgradeable)
    whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, artworksIds, amounts, data);

        if (from == address(0)) {//mint operation
            for (uint256 i = 0; i < artworksIds.length; ++i) {
                unchecked {
                    _artworksInfo[artworksIds[i]].mintedEditions += amounts[i];
                }
            }
        }

        if (to == address(0)) {//burn operation
            for (uint256 i = 0; i < artworksIds.length; ++i) {
                uint256 id = artworksIds[i];
                uint256 amount = amounts[i];
                uint256 supply = _artworksInfo[id].mintedEditions;
                require(supply >= amount, "burn amount exceeds totalSupply");
                unchecked {
                    _artworksInfo[id].mintedEditions = supply - amount;
                }
            }
        }
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    whenNotPaused
    onlyRole(SUPER_ADMIN_ROLE)
    override
    {}

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC1155Upgradeable, AccessControlUpgradeable, ERC2981Upgradeable)
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

    function setArtworkRoyalty(uint256 artworkId, address receiver, uint96 royaltyFeesInBips)
    public
    whenNotPaused
    onlyRole(ADMIN_ROLE) {
        super._setTokenRoyalty(artworkId, receiver, royaltyFeesInBips);
    }

    function resetArtworkRoyalty(uint256 artworkId)
    public
    whenNotPaused
    onlyRole(ADMIN_ROLE) {
        super._resetTokenRoyalty(artworkId);
    }

    /* Opensea creator fee enforcement */

    function setApprovalForAll(address operator, bool approved)
    public
    override
    onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
    public
    override
    onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    public
    virtual
    override
    onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}