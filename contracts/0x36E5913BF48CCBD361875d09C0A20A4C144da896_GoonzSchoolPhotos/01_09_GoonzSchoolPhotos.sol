// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./MultisigOwnable.sol";

contract GoonzSchoolPhotos is ERC165, IERC721, IERC721Metadata, MultisigOwnable {
    using Strings for uint256;

    string private _name;
    string private _symbol;
    IERC721 immutable public ogGoonzNFT;
    IERC721 immutable public portalGoonzNFT;
    address public portalGoonz;
    string public baseURI;

    // EIP2309 Events
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed fromAddress, address indexed toAddress);

    constructor(string memory name_, string memory symbol_, address _ogGoonz, address _portalGoonz, string memory baseURI_) {
        _name = name_;
        _symbol = symbol_;
        ogGoonzNFT = IERC721(_ogGoonz);
        portalGoonzNFT = IERC721(_portalGoonz);
        portalGoonz = _portalGoonz;
        baseURI = baseURI_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) external view virtual override returns (uint256) {
        uint256 balance = ogGoonzNFT.balanceOf(owner);
        balance += portalGoonzNFT.balanceOf(owner);
        return balance;
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address owner) {
        address owner = ogGoonzNFT.ownerOf(tokenId);
        if (owner == portalGoonz) {
            return portalGoonzNFT.ownerOf(tokenId);
        }
        return owner;
    }
    
    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newuri) external onlyRealOwner {
        baseURI = newuri;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        revert("Companion tokens can not be transferred");
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        revert("Companion tokens can not be transferred");
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        revert("Companion tokens can not be transferred");
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return false;
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        revert("Companion tokens can not be transferred");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        revert("Companion tokens can not be transferred");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        revert("Companion tokens can not be manually transferred");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     */
    function exists(uint256 tokenId) public view returns (bool) {
        return ownerOf(tokenId) != address(0);
    }

    function claim(uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(exists(tokenIds[i]), "Token doesn't exist");
            emit Transfer(address(0), ownerOf(tokenIds[i]), tokenIds[i]);
        }
    }

    function initializeToOwners(uint256 start_, uint256 end_) external onlyRealOwner {
        for (uint256 i = start_; i <= end_; i++) {
            emit Transfer(address(0), ownerOf(i), i);
        }
    }

    function initializeBulkSimple(uint256 start_, uint256 end_) external onlyRealOwner {
        emit ConsecutiveTransfer(start_, end_, address(0), address(this));
    }

    function initializeBulk(uint256 start_, uint256 end_, uint256 batchSize) external onlyRealOwner {
        initializeBulkTo(start_, end_, batchSize, address(this));
    }
    
    function initializeBulkTo(uint256 start_, uint256 end_, uint256 batchSize, address to_) public onlyRealOwner  {
        require(end_ > start_, "ending token id must be larger than the starting token id");
        require(end_ - start_ + 1 >= batchSize, "the range of tokens must be bigger than the desired batch size");
        uint256 numOfBatches = (end_ - start_ + 1) / batchSize;
        uint256 lastBatchSize = (end_ - start_ + 1) % batchSize;
        for (uint256 i = 0; i < numOfBatches; i++) {
            emit ConsecutiveTransfer(start_ + batchSize * i, start_ + batchSize * (i+1) - 1, address(0), to_);
        }

        if (lastBatchSize > 0) {
            emit ConsecutiveTransfer(end_ - lastBatchSize + 1, end_, address(0), to_);
        }
    }
}