// SPDX-License-Identifier: Unlicense
// Creator: 0xVeryBased

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./ERC721Storage.sol";

contract ERC721TopLevel is ERC165, Ownable {
    using Address for address;
    using Strings for uint256;

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
    **/
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
    **/
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
    **/
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Storage layer contract that separates out internal minting logic from top level functions
     *   - Designed to reduce top level contract size and enable implementation of additional functionality
    **/
    ERC721Storage public storageLayer;
    bool public storageLayerSet = false;
    modifier onlyStorage() {
        _isStorage();
        _;
    }
    function _isStorage() internal view virtual {
        require(msg.sender == address(storageLayer), "not storage");
    }
    /******************/

    /**
     * @dev Mapping from addresses to whether or not an address is restricted as an operator for all
    **/
    mapping(address => bool) public operatorRestrictions;
    bool public canRestrict = true; // Determines whether or not the contract owner can still restrict any new addresses

    /**
     * @dev Sets the storage layer for this top-level contract and prevents it from being reset
    **/
    function setStorageLayer(address storageLayerAddress_) public onlyOwner {
        require(!storageLayerSet, "sls");
        storageLayer = ERC721Storage(storageLayerAddress_);
        storageLayerSet = true;
    }

    /**
     * @dev get the address of the storage layer contract
    **/
    function _storageLayerAddress() public view returns (address) {
        return address(storageLayer);
    }

    /**
     * @dev Restrict an address from being an operator for all
    **/
    function _restrictOperator(address operator) internal {
        require(canRestrict, "nnr");

        operatorRestrictions[operator] = true;
    }

    /**
     * @dev Release an address from restriction, permitting it to be an operator for all
    **/
    function _releaseOperator(address operator) internal {
        operatorRestrictions[operator] = false;
    }

    /**
     * @dev Prevent the contract owner from restricting any additional operators
    **/
    function _preventNewRestrictions() internal {
        canRestrict = false;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
    **/
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return (interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        interfaceId == type(IERC721Enumerable).interfaceId ||
        super.supportsInterface(interfaceId));
    }

    function totalSupply() public view returns (uint256) {
        return storageLayer.storage_totalSupply();
    }

    function tokenByIndex(uint256 index) public view returns (uint256) {
        return storageLayer.storage_tokenByIndex(index);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        return storageLayer.storage_tokenOfOwnerByIndex(owner, index);
    }

    function tokenOfOwnerByIndexStepped(
        address owner,
        uint256 index,
        uint256 lastToken,
        uint256 lastIndex
    ) public view returns (uint256) {
        return storageLayer.storage_tokenOfOwnerByIndexStepped(
            owner, index, lastToken, lastIndex
        );
    }

    function balanceOf(address owner) public view returns (uint256) {
        return storageLayer.storage_balanceOf(owner);
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        return storageLayer.storage_ownerOf(tokenId);
    }

    function name() public view virtual returns (string memory) {
        return storageLayer.storage_name();
    }

    function symbol() public view virtual returns (string memory) {
        return storageLayer.storage_symbol();
    }

    function approve(address to, uint256 tokenId) public {
        storageLayer.storage_approve(to, tokenId, msg.sender);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        return storageLayer.storage_getApproved(tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public {
        require(!(operatorRestrictions[operator]), "r");

        storageLayer.storage_setApprovalForAll(operator, approved, msg.sender);
    }

    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return storageLayer.storage_isApprovedForAll(owner, operator);
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        storageLayer.storage_transferFrom(from, to, tokenId, msg.sender);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        storageLayer.storage_safeTransferFrom(from, to, tokenId, msg.sender);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        storageLayer.storage_safeTransferFrom(from, to, tokenId, _data, msg.sender);
    }

    function burnToken(uint256 tokenId) public {
        storageLayer.storage_burnToken(tokenId, msg.sender);
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return storageLayer.storage_exists(tokenId);
    }

    function safeMint(address to, uint256 quantity) internal {
        storageLayer.storage_safeMint(to, quantity, msg.sender);
    }

    function safeMint(address to, uint256 quantity, bytes memory _data) internal {
        storageLayer.storage_safeMint(to, quantity, _data, msg.sender);
    }

    function mint(address to, uint256 quantity) internal {
        storageLayer.storage_mint(to, quantity);
    }

    function _contractURI(
        string memory _description,
        string memory _img,
        string memory _self
    ) internal view returns (string memory) {
        return storageLayer.storage_contractURI(_description, _img, _self);
    }

    //////////

    function emitTransfer(address from, address to, uint256 tokenId) public onlyStorage {
        emit Transfer(from, to, tokenId);
    }

    function emitApproval(address owner, address approved, uint256 tokenId) public onlyStorage {
        emit Approval(owner, approved, tokenId);
    }

    function emitApprovalForAll(address owner, address operator, bool approved) public onlyStorage {
        emit ApprovalForAll(owner, operator, approved);
    }
}

////////////////////////////////////////