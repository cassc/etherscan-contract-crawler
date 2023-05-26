// SPDX-License-Identifier: MIT

// Contract by pr0xy.io

pragma solidity ^0.8.7;

import './ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

contract Haki is ERC721A, Ownable, ReentrancyGuard {
    address public vault;
    bytes32 public merkleRoot;
    string public baseTokenURI;
    uint public price;
    uint public status;

    constructor(uint _price, address _vault) ERC721A("Haki", "HAKI") {
        setPrice(_price);
        setVault(_vault);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenURI(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setPrice(uint _price) public onlyOwner {
        price = _price;
    }

    function setStatus(uint _status) external onlyOwner {
        status = _status;
    }

    function setVault(address _vault) public onlyOwner {
        vault = _vault;
    }

    function presale(bytes32[] calldata _merkleProof, uint _purchaseAmount, uint _freeAmount) external nonReentrant payable {
        uint amount = _purchaseAmount + _freeAmount;
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _purchaseAmount, _freeAmount));

        require(status == 1, 'Not Active');
        require(tx.origin == msg.sender, 'Contract Denied');
        require(_totalMinted() + amount < 5001, 'Supply Denied');
        require(!(_numberMinted(msg.sender) > 0), 'Mint Claimed');
        require(msg.value >= price * _purchaseAmount, 'Ether Amount Denied');
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Proof Invalid');

        _safeMint(msg.sender, amount);
    }

    function mint(uint _amount) external nonReentrant payable {
        require(status == 2, 'Not Active');
        require(_amount < 4, 'Amount Denied');
        require(tx.origin == msg.sender, 'Contract Denied');
        require(_totalMinted() + _amount < 5001, 'Supply Denied');
        require(msg.value >= price * _amount, 'Ether Amount Denied');

        _safeMint(msg.sender, _amount);
    }

    function withdraw() external nonReentrant payable onlyOwner {
        payable(vault).transfer(address(this).balance);
    }
}