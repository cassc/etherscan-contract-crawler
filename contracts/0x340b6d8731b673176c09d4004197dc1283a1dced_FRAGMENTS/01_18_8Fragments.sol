// SPDX-License-Identifier: MIT

// FRAGMENTS by 8th Project
// author: sadat.eth

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ClosedSeaOperatorFilterer.sol";

contract FRAGMENTS is ERC721, ERC2981, ReentrancyGuard, Ownable, OperatorFilterer {
    using Strings for uint256;

    uint256 public maxSupply = 100;
    uint256 public mintPrice = 0.05 ether;
    uint256 public maxMintPerTx = 10;
    uint256 public totalSupply;

    string public baseURI = "ipfs://bafkreih7mrq3ouzigy63l5rllloiso3wl7cvmdykba3yjhh4gag32d64ka/?";
    string public contractURI = "ipfs://bafkreiheplq4ytjvrng6n6azswx25f3c2vv2qzqdgyt3cv3222pujaj3du/";
    address private creator = 0x627137FC6cFa3fbfa0ed936fB4B5d66fB383DBE8;
    bytes32 private collectors = 0x3fc3e57c72903ae7daff0ebb2187c6e96be0e49fc1892774e7e88bdc35240768;

    bool public allowList = true;
    bool public operatorFilteringEnabled = true;
    
    error invalidFragment();
    error holderOnly();
    error keepItFair();
    error soldOut();
    error sendEth();
    error noBots();
    
    constructor() ERC721("FRAGMENTS", "8") {
        _registerForOperatorFiltering();
        _setDefaultRoyalty(creator, 800); // 8%
    }

    // Mint function allowlist & public

    function mint(uint256 amount, bytes32[] calldata proof) public payable check() {
        if (allowList) {
            if (!_verify(msg.sender, proof)) revert holderOnly();
        }
        if (amount > maxMintPerTx) revert keepItFair();
        if (totalSupply + amount > maxSupply) revert soldOut();
        if (msg.value < mintPrice * amount) revert sendEth();

        uint256 currentTokendId = totalSupply;
        for (uint256 i = 0; i < amount; ++i) {
            ++currentTokendId;
            _mint(msg.sender, currentTokendId);
        }
        totalSupply += amount;
    }

    // Custom functions internal

    modifier check() {
        if (msg.sender != tx.origin) revert noBots();
        _;
    }

    function _verify(address account, bytes32[] memory proof) internal view returns (bool verify_) {
        return MerkleProof.verify(proof, collectors, keccak256(abi.encodePacked(account, uint256(1))));
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    // Custom functions public onlyOwner

    function setSale() public onlyOwner {
        allowList = !allowList;
    }

    function setReveal(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setDefaultRoyalty(address receiver, uint96 feeBps) public onlyOwner {
        _setDefaultRoyalty(receiver, feeBps);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool success, ) = payable(creator).call{value: address(this).balance}("");
        require(success);
    }

    // Standard functions public overrides

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

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId) public view override (ERC721, ERC2981) returns (bool) {
        return ERC721.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        if (!_exists(_tokenId)) revert invalidFragment();
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }
}