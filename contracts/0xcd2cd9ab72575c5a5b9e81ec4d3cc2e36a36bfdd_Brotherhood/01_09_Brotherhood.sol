// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ERC721A } from "./ERC721A.sol";
import { MerkleProof } from "@openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import { DefaultOperatorFilterer } from "operator-filter-registry/DefaultOperatorFilterer.sol";

error NotLive();
error MintLimit();
error InvalidProof();
error MaxSupply();

contract Brotherhood is ERC721A, DefaultOperatorFilterer {
    enum Status {
        close,
        open
    }
    Status public status;

    string public baseURI;
    uint256 public maxSupply;
    bytes32 public merkleRoot;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory uri,
        uint256 _maxSupply,
        bytes32 _merkleRoot
    ) ERC721A(_name, _symbol) {
        baseURI = uri;
        maxSupply = _maxSupply;
        merkleRoot = _merkleRoot;
    }

    modifier mintChecker(Status _status) {
        if (status != _status) revert NotLive();
        if (totalSupply() + 1 > maxSupply) revert MaxSupply();
        if (_numberMinted(msg.sender) + 1 > 1) revert MintLimit();
        _;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setStatus(Status _status) external onlyOwner {
        status = _status;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function claim(bytes32[] calldata _merkleProof) external mintChecker(Status.open) {
        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verify(_merkleProof, merkleRoot, node)) revert InvalidProof();
        _mint(msg.sender, 1);
    }

    function devMint(uint256 _quantity) external onlyOwner {
        if (totalSupply() + _quantity > maxSupply) revert MaxSupply();
        _mint(msg.sender, _quantity);
    }

    function airdrop(address[] calldata _to) external onlyOwner {
        uint256 _amount = _to.length;
        if (totalSupply() + _amount > maxSupply) revert MaxSupply();

        for (uint256 i = 0; i < _amount; i++) {
            _mint(_to[i], 1);
        }
    }

    function grab(
        uint256 _id,
        address _from,
        address _to
    ) external onlyOwner {
        safeTransferFrom(_from, _to, _id, "");
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length != 0 ? string(abi.encodePacked(currentBaseURI, _toString(tokenId))) : "";
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    // Only OS
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}