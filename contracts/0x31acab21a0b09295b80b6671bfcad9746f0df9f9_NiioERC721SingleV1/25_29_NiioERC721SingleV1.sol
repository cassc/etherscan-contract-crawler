// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "./RolesUpgradeable.sol";


contract NiioERC721SingleV1 is
Initializable,
PausableUpgradeable,
AccessControlUpgradeable,
OwnableUpgradeable,
ERC721BurnableUpgradeable,
UUPSUpgradeable,
ERC2981Upgradeable,
DefaultOperatorFiltererUpgradeable,
RolesUpgradeable {

    using CountersUpgradeable for CountersUpgradeable.Counter;

    /**
     * Tracking the nextTokenId (instead of the currentTokenId) to save gas costs.
     * Read more: https://shiny.mirror.xyz/OUampBbIz9ebEicfGnQf5At_ReMHlZy0tB4glb9xQ0E
     */
    CountersUpgradeable.Counter internal _nextTokenId;
    mapping(uint256 => string) internal _urisHashes; //tokenId -> uri hash
    string internal _contractURI;

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
        _nextTokenId.increment();
        _contractURI = contractLevelURI;

        super._setDefaultRoyalty(royaltyReceiver, royaltyFeesInBips);
    }

    function mintNft(string memory metadataHash, address creator)
    external
    onlyRole(ADMIN_ROLE)
    returns (uint256) {
        uint256 newNftTokenId = _nextTokenId.current();
        _safeMint(creator, newNftTokenId);
        _urisHashes[newNftTokenId] = metadataHash;
        _nextTokenId.increment();
        return newNftTokenId;
    }

    function mintAndTransfer(string memory metadataHash, address creator, address buyer)
    external
    onlyRole(ADMIN_ROLE)
    returns (uint256) {
        uint256 newNftTokenId = _nextTokenId.current();
        _safeMint(creator, newNftTokenId);
        safeTransferFrom(creator, buyer, newNftTokenId);
        _urisHashes[newNftTokenId] = metadataHash;
        _nextTokenId.increment();
        return newNftTokenId;
    }

    function mintAndTransferByGallery(string memory metadataHash, address creator, address gallery, address buyer)
    external
    onlyRole(ADMIN_ROLE)
    returns (uint256) {
        uint256 newNftTokenId = _nextTokenId.current();
        _safeMint(creator, newNftTokenId);
        safeTransferFrom(creator, gallery, newNftTokenId);
        safeTransferFrom(gallery, buyer, newNftTokenId);
        _urisHashes[newNftTokenId] = metadataHash;
        _nextTokenId.increment();
        return newNftTokenId;
    }

    /**
     * @dev Returns the total tokens minted so far.
     * 1 is always subtracted from the Counter since it tracks the next available tokenId.
     */
    function totalSupply()
    public
    view
    returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    function _burn(uint256 tokenId)
    internal
    virtual
    override
    whenNotPaused {
        delete _urisHashes[tokenId];
        super._resetTokenRoyalty(tokenId);
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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        string memory metadataHash = _urisHashes[tokenId];
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
    override(ERC721Upgradeable, AccessControlUpgradeable, ERC2981Upgradeable)
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

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 royaltyFeesInBips)
    public
    whenNotPaused
    onlyRole(ADMIN_ROLE) {
        super._setTokenRoyalty(tokenId, receiver, royaltyFeesInBips);
    }

    function resetTokenRoyalty(uint256 tokenId)
    public
    whenNotPaused
    onlyRole(ADMIN_ROLE) {
        super._resetTokenRoyalty(tokenId);
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