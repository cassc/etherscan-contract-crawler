// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./finance/PaymentSplitter.sol";
import "./extensions/ERC721AQueryable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Phellas is ERC721AQueryable, PaymentSplitter, Ownable, DefaultOperatorFilterer{
    using Strings for uint256;

    string private _baseURI_;
    string private _contractURI;
    address private _openSeaProxy;

    uint256 public maxSupply;

    uint256 public publicCost;
    uint256 public whitelistCost;

    bytes32 public whitelistMerkleRoot;
    uint256 public whitelistMintDate = 1669816800; // 2022-11-30T14:00:00Z
    uint256 public publicMintDate = 1669896000; // 2022-11-01T12:00:00Z
    uint256 public maxPublicPrivateMint = 10;
    uint256 public maxWhitePrivateMint = 10;

    mapping(address => uint256) private _whitelistMinted;
    mapping(address => uint256) private _publicMinted;

    event baseURIUpdated(string baseURI);
// event PermanentURI(string _value, uint256 indexed _id);

    constructor (string memory name_,
        string memory symbol_,
        uint256 maxSupply_,
        string memory baseURI_,
        string memory contractURI_,
        address openSeaProxy_,
        uint256 publicCost_,
        uint256 whitelistCost_,
        address[] memory payees_,
        uint256[] memory payeeShares_
    )
    ERC721A(name_, symbol_) PaymentSplitter(payees_, payeeShares_) {
        _baseURI_ = baseURI_;
        _contractURI = contractURI_;
        _openSeaProxy = openSeaProxy_;
        maxSupply = maxSupply_;
        publicCost = publicCost_;
        whitelistCost = whitelistCost_;
    }

    // Overwrite some default functions to prevent errors
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC721A) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Mint for whitelisted users
     */
    function mintWhitelist(uint256 amount, bytes32[] calldata _merkleProof) public payable {
        require(block.timestamp >= whitelistMintDate, "mintWhitelist: The whitelist sale date is not yet passed");
        require(msg.value >= (whitelistCost * amount), "mintWhitelist: Insufficient funds");
        require((_whitelistMinted[_msgSender()] + amount) <= maxWhitePrivateMint, "mintWhitelist: Personal whitelist limit reached");

        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf), "mintWhitelist: Invalid merkle proof");

        _privateMint(_msgSender(), amount);
        _whitelistMinted[_msgSender()] += amount;
    }

    /**
     * @dev Mint for public users
     */
    function mintPublic(uint256 amount) public payable {
        require(block.timestamp >= publicMintDate, "mintPublic: The public sale date is not yet passed");
        require(msg.value >= publicCost * amount, "mintPublic: Insufficient funds");
        require((_publicMinted[_msgSender()] + amount) <= maxPublicPrivateMint, "mintPublic: Personal public limit reached");

        _privateMint(_msgSender(), amount);
        _publicMinted[_msgSender()] += amount;
    }

    /**
     * @dev Mint tokens for user with the MINTER_ROLE
     */
    function mintOwner(address to, uint256 amount) public onlyOwner {
        _privateMint(to, amount);
    }

    function _privateMint(address to, uint256 amount) internal virtual {
        require((_nextTokenId() + amount) <= maxSupply, "mint: max supply reached");
        _mint(to, amount);
    }

    function getPersonalWhitelistMintCount(address owner) public view returns (uint256) {
        return _whitelistMinted[owner];
    }
    function getPersonalPublicCount(address owner) public view returns (uint256) {
        return _publicMinted[owner];
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return bytes(_baseURI_).length > 0 ? string(abi.encodePacked(_baseURI_, tokenId.toString(), ".json")) : "";
    }

    /**
     * @dev Sets `_baseURI_`
     */
    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseURI_ = baseURI_;
        emit baseURIUpdated(baseURI_);
    }
    /**
     * @dev Sets `_contractURI`
     */
    function setContractURI(string memory contractURI_) public onlyOwner {
        _contractURI = contractURI_;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /*
    * @dev Set Whitelist release variables
    */
    function setWhitelistCost(uint256 _whitelistCost) public onlyOwner{
        whitelistCost = _whitelistCost;
    }
    function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot) public onlyOwner{
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }
    function setWhitelistMintDate(uint256 _whitelistMintDate) public onlyOwner{
        whitelistMintDate = _whitelistMintDate;
    }

    /*
    * @dev Set Public release variables
    */
    function setPublicCost(uint256 _publicCost) public onlyOwner{
        publicCost = _publicCost;
    }
    function setPublicMintDate(uint256 _publicMintDate) public onlyOwner{
        publicMintDate = _publicMintDate;
    }

    /**
     * @dev Sets `_openSeaProxy`
     */
//    function setOpenSeaProxy(address openSeaProxy_) public onlyOwner {
//        _openSeaProxy = openSeaProxy_;
//    }

   /**
   * Override isApprovedForAll to auto-approve OS's proxy contract
   */
    function isApprovedForAll(address owner, address operator) public override(IERC721A, ERC721A) view returns (bool) {
        // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        // for Polygon's Mumbai testnet, use 0xff7Ca10aF37178BdD056628eF42fD7F799fAc77c
        if (operator == _openSeaProxy) {
            return true;
        }

        // otherwise, use the default ERC721.isApprovedForAll()
        return super.isApprovedForAll(owner, operator);
    }

    function setApprovalForAll(address operator, bool approved) public override(IERC721A, ERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override(IERC721A, ERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    payable
    override(IERC721A, ERC721A)
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}