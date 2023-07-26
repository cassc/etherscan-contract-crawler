// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/OperatorFilterer.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract TheNexus is ERC1155, Ownable, OperatorFilterer {
    constructor(string memory _URI) ERC1155('https://metag-backend.herokuapp.com/thenexus/}') OperatorFilterer(address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6), false){}

    IERC721 public METAG;

    uint public publicPrice = 0.029 ether;
    uint public presalePrice = 0.029 ether;
    uint public maxSupply = 3000;
    uint public maxTx = 20;

    uint public edition = 0;

    bytes32 public merkleRoot;

    bool public _mintOpen = false;
    bool public _presaleOpen = false;

    mapping(uint256 => uint256) public minted;
    mapping(address => bool) private metagBonus;
    
    function toggleMint() external onlyOwner {
        _mintOpen = !_mintOpen;
    }

    function togglePresale() external onlyOwner {
        _presaleOpen = !_presaleOpen;
    }
    
    function setPresalePrice(uint newPrice) external onlyOwner {
        presalePrice = newPrice;
    }

    function setPublicPrice(uint newPrice) external onlyOwner {
        publicPrice = newPrice;
    }

    function setMetagAddress(address newAddress) external onlyOwner {
        METAG = IERC721(newAddress);
    }
    
    function setURI(string memory newBaseURI) external onlyOwner {
        _setURI(newBaseURI);
    }

    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
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

    function mintPresale(uint qty, bytes32[] memory proof) external payable {
        require(_presaleOpen, "store closed");
        require(qty <= maxTx && qty > 0, "TRANSACTION: qty of mints not alowed");
        require(msg.value >= presalePrice * qty, "PAYMENT: invalid value");
        if (METAG.balanceOf(_msgSender()) > 0 && !metagBonus[_msgSender()]) qty += 1;
        require(qty + minted[edition] <= maxSupply, "SUPPLY: Value exceeds totalSupply");
        require(_verify(proof), "address not in whitelist");
        _mint(_msgSender(), edition, qty, "");
        minted[edition] += qty;
    }
    
    function mintPublic(uint qty) external payable {
        require(_mintOpen, "store closed");
        require(qty <= maxTx && qty > 0, "TRANSACTION: qty of mints not alowed");
        require(msg.value >= publicPrice * qty, "PAYMENT: invalid value");
        if (METAG.balanceOf(_msgSender()) > 0 && !metagBonus[_msgSender()]) qty += 1;
        require(qty + minted[edition] <= maxSupply, "SUPPLY: Value exceeds totalSupply");
        _mint(_msgSender(), edition, qty, "");
        minted[edition] += qty;
    }
    
    function withdraw() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }

    function _verify(bytes32[] memory proof) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }
}