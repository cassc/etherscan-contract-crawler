// SPDX-License-Identifier: Unlicense
// Creator: Mr. Masterchef

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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
    ERC721StorageProto public storageLayer;
    bool public storageLayerSet = false;
    modifier onlyStorage() {
        _isStorage();
        _;
    }
    function _isStorage() internal view virtual {
        require(msg.sender == address(storageLayer), "not storage");
    }

    /******************/

    constructor() Ownable() {}

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
        storageLayer = ERC721StorageProto(storageLayerAddress_);
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
        return storageLayer.storage_totalSupply(address(this));
    }

    function tokenByIndex(uint256 index) public view returns (uint256) {
        return storageLayer.storage_tokenByIndex(address(this), index);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        return storageLayer.storage_tokenOfOwnerByIndex(address(this), owner, index);
    }

    function tokenOfOwnerByIndexStepped(
        address owner,
        uint256 index,
        uint256 lastToken,
        uint256 lastIndex
    ) public view returns (uint256) {
        return storageLayer.storage_tokenOfOwnerByIndexStepped(
            address(this), owner, index, lastToken, lastIndex
        );
    }

    function balanceOf(address owner) public view returns (uint256) {
        return storageLayer.storage_balanceOf(address(this), owner);
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        return storageLayer.storage_ownerOf(address(this), tokenId);
    }

    function name() public view virtual returns (string memory) {
        return storageLayer.storage_name(address(this));
    }

    function symbol() public view virtual returns (string memory) {
        return storageLayer.storage_symbol(address(this));
    }

    function approve(address to, uint256 tokenId) public {
        storageLayer.storage_approve(msg.sender, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        return storageLayer.storage_getApproved(address(this), tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public {
        require(!(operatorRestrictions[operator]), "r");

        storageLayer.storage_setApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return storageLayer.storage_isApprovedForAll(address(this), owner, operator);
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        storageLayer.storage_transferFrom(msg.sender, from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        storageLayer.storage_safeTransferFrom(msg.sender, from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        storageLayer.storage_safeTransferFrom(msg.sender, from, to, tokenId, _data);
    }

    function burnToken(uint256 tokenId) public {
        storageLayer.storage_burnToken(msg.sender, tokenId);
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return storageLayer.storage_exists(address(this), tokenId);
    }

    function contractURI() public view returns (string memory) {
        return storageLayer.storage_contractURI(address(this));
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

    //////////

    receive() external payable {
        (bool success, ) = payable(storageLayer.mintingContract()).call{value: msg.value}("");
        require(success, "F");
    }

    function withdrawTokens(address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
    }
}

////////////////////

abstract contract ERC721StorageProto {
    address public mintingContract;

    //////////

    function registerTopLevel(
        string memory name_,
        string memory symbol_,
        string memory description_,
        string memory image_
    ) public virtual;

    //////////

    function storage_totalSupply(address collection) public view virtual returns (uint256);

    function storage_tokenByIndex(address collection, uint256 index) public view virtual returns (uint256);

    function storage_tokenOfOwnerByIndex(
        address collection,
        address owner,
        uint256 index
    ) public view virtual returns (uint256);

    function storage_tokenOfOwnerByIndexStepped(
        address collection,
        address owner,
        uint256 index,
        uint256 lastToken,
        uint256 lastIndex
    ) public view virtual returns (uint256);

    function storage_balanceOf(address collection, address owner) public view virtual returns (uint256);

    function storage_ownerOf(address collection, uint256 tokenId) public view virtual returns (address);

    function storage_name(address collection) public view virtual returns (string memory);

    function storage_symbol(address collection) public view virtual returns (string memory);

    function storage_approve(address msgSender, address to, uint256 tokenId) public virtual;

    function storage_getApproved(address collection, uint256 tokenId) public view virtual returns (address);

    function storage_setApprovalForAll(address msgSender, address operator, bool approved) public virtual;

    function storage_isApprovedForAll(
        address collection,
        address owner,
        address operator
    ) public view virtual returns (bool);

    function storage_transferFrom(
        address msgSender,
        address from,
        address to,
        uint256 tokenId
    ) public virtual;

    function storage_safeTransferFrom(
        address msgSender,
        address from,
        address to,
        uint256 tokenId
    ) public virtual;

    function storage_safeTransferFrom(
        address msgSender,
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual;

    function storage_burnToken(address msgSender, uint256 tokenId) public virtual;

    function storage_exists(address collection, uint256 tokenId) public view virtual returns (bool);

    function storage_safeMint(address msgSender, address to, uint256 quantity) public virtual;

    function storage_safeMint(
        address msgSender,
        address to,
        uint256 quantity,
        bytes memory _data
    ) public virtual;

    function storage_mint(address msgSender, address to, uint256 quantity) public virtual;

    function storage_contractURI(address collection) public view virtual returns (string memory);
}

////////////////////////////////////////