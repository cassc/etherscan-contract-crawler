// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./ERC721A/ERC721A.sol";

contract MaiShiranui is Ownable, ERC721A, ReentrancyGuard, DefaultOperatorFilterer {
    using Strings for uint256;

    constructor() ERC721A("Mai Shiranui","MAI") {}

    uint256 public maxSupply = 7777;
    uint256 public maxWLMinted = 2;

    uint256 public wlMintStartTime = 1677124800;
    uint256 public wlMintEndTime = 1677153599;
    uint256 public wlPrice = 0.04 ether;

    uint256 public pMintStartTime = 1677153600;
    uint256 public pMintEndTime = 1677240000;
    uint256 public pPrice = 0.05 ether;

    bytes32 public merkleRoot;
    bool public saleIsActive = true;

    event FlipSaleState();
    event UpdatePlaNftMintLimit(uint256);

    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
        emit FlipSaleState();
    }

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    function setWlTime(uint256 _startTime, uint256 _endTime) external onlyOwner {
        wlMintStartTime = _startTime;
        wlMintEndTime = _endTime;
    }

    function setWlPrice(uint256 _price) external onlyOwner {
        wlPrice = _price;
    }

    function setWLMaxMint(uint256 _max) external onlyOwner {
        maxWLMinted = _max;
    }

    function setPTime(uint256 _startTime, uint256 _endTime) external onlyOwner {
        pMintStartTime = _startTime;
        pMintEndTime = _endTime;
    }

    function setPPrice(uint256 _price) external onlyOwner {
        pPrice = _price;
    }

    address public kcs;

    function setK(address _new) external onlyOwner {
        kcs = _new;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    string private _baseTokenURI = "ipfs://bafybeidlovo34kdh6d7y5w2pglseqvoyswvh5gi4gbi7g4hwlnwvoohafm/";

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata _uri) external onlyOwner {
        _baseTokenURI = _uri;
    }

    string public suffixUri = ".json";

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

    function ownerMint(uint256 _amount, address _to) external onlyOwner {
        _safeMint(_to, _amount);
    }

    function whitelistMint(bytes32[] calldata _merkleProof, uint256 _quantity)
    external
    payable
    nonReentrant
    {
        require(saleIsActive, "Not allowed to mint");
        require(_quantity > 0, "Wrong amount of minting");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "NOT incorporated in the whitelists");
        require(block.timestamp > wlMintStartTime, "Wrong time for whitelist to mint");
        require(block.timestamp < wlMintEndTime, "Wrong time for whitelist to mint");
        uint256 _maxWLMinted = maxWLMinted;
        uint256 kcsOwned = ERC721A(kcs).balanceOf(msg.sender);
        if(kcsOwned >= 1) {_maxWLMinted = 5;}
        uint256 numMinted = balanceOf(msg.sender);
        require(numMinted + _quantity <= _maxWLMinted, "Exceed the limit of mint amount");
        require(totalSupply() + _quantity <= maxSupply, "sold out");
        require(msg.value >= wlPrice * _quantity, "Insufficient value");
        _safeMint(msg.sender, _quantity);
    }

    uint256 public mintFromFeoCount = 0;

    function publicMint(uint256 _quantity) external payable nonReentrant {
        require(saleIsActive, "Not allowed to mint");
        require(_quantity > 0, "Wrong amount of minting");
        require(block.timestamp > pMintStartTime, "Wrong time for mint");
        require(block.timestamp < pMintEndTime, "Wrong time for mint");
        require(msg.value >= pPrice * _quantity, "Insufficient value");

        require(totalSupply() + _quantity <= maxSupply, "sold out");
        mintFromFeoCount += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    uint256 public mintFromPlaNftCount = 0;
    uint256 public plaNftMintLimit = 400;

    function updatePlaNftMintLimit(uint256 _limit) external onlyOwner {
        plaNftMintLimit = _limit;
        emit UpdatePlaNftMintLimit(_limit);
    }

    function planftMint(uint256 _quantity) external payable nonReentrant {
        require(saleIsActive, "Not allowed to mint");
        require(_quantity > 0, "Wrong amount of minting");
        require(block.timestamp > pMintStartTime, "Wrong time for mint");
        require(block.timestamp < pMintEndTime, "Wrong time for mint");
        require(msg.value >= pPrice * _quantity, "Insufficient value");
        require(totalSupply() + _quantity <= maxSupply);
        require(_quantity + mintFromPlaNftCount <= plaNftMintLimit, "sold out");
        mintFromPlaNftCount += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    receive() external payable {}

    function withdrawETH() external onlyOwner nonReentrant {
        (bool success, ) = address(msg.sender).call{value: address(this).balance}("");
        require(success, "transfer failed");
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
}