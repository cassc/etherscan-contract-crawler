// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721A/ERC721A.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {DefaultOperatorFilterer} from "./Blur/DefaultOperatorFilterer.sol";

contract AntiOS is ERC721A("Anti OS", "AO"), ERC2981, Ownable, DefaultOperatorFilterer {
    uint256 public immutable MaxWalletPerToken = 2;
    uint256 public immutable MaxSupply = 55;
    mapping(address => uint256) public minted;
    bytes32 public whiteListMerkleRoot;
    string private _baseTokenUri = "QmSYHNqjLSe8UPQaPGCXnqn2aBqtbZNsgiyTFbpkVKixmW";


    constructor() {
        _ownerMint(10);
    }

    modifier onlyEOA() {
        require(tx.origin == msg.sender, "Not EOA");
        _;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return 
            ERC721A.supportsInterface(interfaceId) || 
            ERC2981.supportsInterface(interfaceId);
    }

    modifier validateAddress(bytes32[] calldata merkleProof) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, whiteListMerkleRoot, leaf), "Not in WL");
        _;
    }

    function setBaseUri(string memory newUri) external onlyOwner {
        _baseTokenUri = newUri;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory) {
        return _baseTokenUri;
    }

    function setMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whiteListMerkleRoot = merkleRoot;
    }

    function mint(uint256 quantity, bytes32[] calldata proof) external validateAddress(proof) onlyEOA {
        require(minted[msg.sender] + quantity <= MaxWalletPerToken && totalSupply() + quantity <= MaxSupply, "Cannot mint any more");

        minted[msg.sender] += quantity;
        _mint(msg.sender, quantity);
    }

    function _ownerMint(uint256 quantity) internal {
        _mint(owner(), quantity);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override onlyAllowedOperator(from){
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    function withdrawETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}