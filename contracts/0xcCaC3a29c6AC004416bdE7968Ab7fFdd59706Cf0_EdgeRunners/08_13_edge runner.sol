// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./ERC721A/ERC721A.sol";


contract EdgeRunners is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIds;

    constructor() ERC721A("EdgeRunners","ER") {}

    uint256 public maxSupply = 10000;
    uint256 public wlMintStartTime = 1672228800;
    uint256 public wlMintEndTime = 1672315200;
    uint256 public wlPrice = 0.035 ether;
    uint256 public maxMinted = 3;

    uint256 public pMintStartTime = 1672315201;
    uint256 public pPrice = 0.045 ether;

    string private _baseTokenURI = "ipfs://bafybeidmrsvehl4ehipm5qqvgegi33r6nhr26ehvs3va6ujd6fqq6q7b5y/";
    string public suffixUri = ".json";

    bytes32 public merkleRoot;
    bool public saleIsActive = true;

    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function setWlTime(uint256 _startTime, uint256 _endTime) external onlyOwner {
        wlMintStartTime = _startTime;
        wlMintEndTime = _endTime;
    }
    function setWlPrice(uint256 _price) external onlyOwner {
        wlPrice = _price;
    }
    function setMaxMintCount(uint256 _max) external onlyOwner {
        maxMinted = _max;
    }

    function setPTime(uint256 _startTime) external onlyOwner {
        pMintStartTime = _startTime;
    }
    function setPPrice(uint256 _price) external onlyOwner {
        pPrice = _price;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    override
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    function setBaseURI(string calldata _uri) external onlyOwner {
        _baseTokenURI = _uri;
    }

    function setSuffixUri(string calldata _suffix) internal onlyOwner {
        suffixUri = _suffix;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return
            bytes(_baseURI()).length != 0
                ? string(abi.encodePacked(_baseURI(), _tokenId.toString(), suffixUri))
                : "";
    }

    function whitelistMint(bytes32[] calldata _merkleProof, uint256 _quantity)
    external
    payable
    callerIsUser
    nonReentrant
    {
        require(saleIsActive, "Not allowed to mint");
        // verify limit per account
        require(_quantity > 0, "Wrong amount of minting");
        require(_numberMinted(msg.sender) + _quantity <= maxMinted, "Exceed the limit of mint amount");
        // verify merkle
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "NOT incorporated in the whitelists");
        // verify start/end time
        require(block.timestamp > wlMintStartTime, "Wrong time for whitelist to mint");
        require(block.timestamp < wlMintEndTime, "Wrong time for whitelist to mint");
        // verify mint price
        require(msg.value >= wlPrice * _quantity, "Insufficient value");
        // verify mint max count
        require(totalSupply() + _quantity <= maxSupply);
        _safeMint(msg.sender, _quantity);
    }

    function publicMint(uint256 _quantity) external payable callerIsUser nonReentrant {
        require(saleIsActive, "Not allowed to mint");
        require(_quantity > 0, "Wrong amount of minting");
        // verify start/end time
        require(block.timestamp > pMintStartTime, "Wrong time for public mint");
        // verify mint price
        require(msg.value >= pPrice * _quantity, "Insufficient value");
        // verify mint max count
        require(totalSupply() + _quantity <= maxSupply);
        _safeMint(msg.sender, _quantity);
    }

    function withdrawETH() external onlyOwner {
        payable(address(owner())).transfer(address(this).balance);
    }

    receive() external payable {}
}