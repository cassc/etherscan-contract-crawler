// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {DefaultOperatorFilterer} from "operator-filter-registry/src/DefaultOperatorFilterer.sol";


contract TheNexus is ERC1155, ERC2981, Ownable, DefaultOperatorFilterer {
    constructor(string memory _URI) ERC1155('https://metag-backend.herokuapp.com/thenexus/}') {}

    uint public publicPrice = 0.029 ether;
    uint public maxSupply = 3000;
    uint public maxTx = 20;

    uint public edition = 0;

    bytes32 public guardianMerkleRoot;

    bool public _mintOpen = false;

    mapping(uint256 => uint256) public minted;
    mapping(address => bool) private metagBonus;
    
    function toggleMint() external onlyOwner {
        _mintOpen = !_mintOpen;
    }

    function setPublicPrice(uint newPrice) external onlyOwner {
        publicPrice = newPrice;
    }
    
    function setURI(string memory newBaseURI) external onlyOwner {
        _setURI(newBaseURI);
    }

    function setGuardianMerkleRoot(bytes32 root) external onlyOwner {
        guardianMerkleRoot = root;
    }
    
    function setMaxSupply(uint newSupply) external onlyOwner {
        maxSupply = newSupply;
    }

    function setEdition(uint ed) external onlyOwner {
        edition = ed;
    }
    
    function setMaxTx(uint newMax) external onlyOwner {
        maxTx = newMax;
    }

    function mintTeam(uint qty)
        external
        onlyOwner
    {
        _mint(_msgSender(), edition, qty, "");
        minted[edition] += qty;
    }

    function mintGuardianHolder(uint qty, bytes32[] memory proof) external payable {
        require(_mintOpen, "store closed");
        require(qty <= maxTx && qty > 0, "TRANSACTION: qty of mints not alowed");
        require(msg.value >= publicPrice * qty, "PAYMENT: invalid value");
        if (_verifyGuardianHolder(proof) && !metagBonus[_msgSender()]) {
            qty += 1;
            metagBonus[_msgSender()] = true;
        } 
        require(qty + minted[edition] <= maxSupply, "SUPPLY: Value exceeds totalSupply");
        _mint(_msgSender(), edition, qty, "");
        minted[edition] += qty;
    }
    
    function mint(uint qty) external payable {
        require(_mintOpen, "store closed");
        require(qty <= maxTx && qty > 0, "TRANSACTION: qty of mints not alowed");
        require(msg.value >= publicPrice * qty, "PAYMENT: invalid value");
        require(qty + minted[edition] <= maxSupply, "SUPPLY: Value exceeds totalSupply");
        _mint(_msgSender(), edition, qty, "");
        minted[edition] += qty;
    }
    
    function withdraw() external onlyOwner {
        payable(address(0x8F14068Bf2003B75E06F268E7D70184E5FBB5972)).transfer(address(this).balance);
    }

    function _verifyGuardianHolder(bytes32[] memory proof) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(proof, guardianMerkleRoot, leaf);
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}