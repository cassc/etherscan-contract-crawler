// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import './ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

contract Apiens is ERC721A, Ownable, ReentrancyGuard {
    address public vault;
    bytes32 public claimMerkleRoot;
    bytes32 public merkleRoot;
    string public baseTokenURI;
    uint public price;
    uint public status;

    uint public mintLimit = 3;
    uint public presaleMintLimit = 2;
    uint public maxSupply = 8000;

    mapping(address => bool) public denylist;

    constructor() ERC721A("Apiens", "APIENS") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenURI(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setClaimMerkleRoot(bytes32 _claimMerkleRoot) external onlyOwner {
        claimMerkleRoot = _claimMerkleRoot;
    }

    function setMaxSupply(uint _maxSupply) external onlyOwner {
        require(_maxSupply < maxSupply, 'Invalid Supply');
        maxSupply = _maxSupply;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setMintLimit(uint _mintLimit) public onlyOwner {
        mintLimit = _mintLimit;
    }

    function setPresaleMintLimit(uint _presaleMintLimit) public onlyOwner {
        presaleMintLimit = _presaleMintLimit;
    }

    function setPrice(uint _price) external onlyOwner {
        price = _price;
    }

    function setStatus(uint _status) external onlyOwner {
        status = _status;
    }

    function setVault(address _vault) external onlyOwner {
        vault = _vault;
    }

    function getMints(address _wallet) external view returns (uint) {
        return _numberMinted(_wallet);
    }

    function claim(bytes32[] calldata _merkleProof, uint _amount) external nonReentrant {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _amount));

        require(status == 1, 'Not Active');
        require(tx.origin == msg.sender, 'Contract Denied');
        require(_totalMinted() + _amount <= maxSupply, 'Supply Denied');
        require(!denylist[msg.sender], 'Mint Claimed');
        require(MerkleProof.verify(_merkleProof, claimMerkleRoot, leaf), 'Proof Invalid');

        _safeMint(msg.sender, _amount);
        denylist[msg.sender] = true;
    }

    function presale(bytes32[] calldata _merkleProof, uint _amount) external nonReentrant payable {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        require(status == 2, 'Not Active');
        require(tx.origin == msg.sender, 'Contract Denied');
        require(_totalMinted() + _amount <= maxSupply, 'Supply Denied');
        require(_amount + _numberMinted(msg.sender) <= presaleMintLimit, 'Amount Denied');
        require(msg.value >= price * _amount, 'Ether Amount Denied');
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Proof Invalid');

        _safeMint(msg.sender, _amount);
    }

    function mint(uint _amount) external nonReentrant payable {
        require(status == 3, 'Not Active');
        require(tx.origin == msg.sender, 'Contract Denied');
        require(_totalMinted() + _amount <= maxSupply, 'Supply Denied');
        require(_amount <= mintLimit, 'Amount Denied');
        require(msg.value >= price * _amount, 'Ether Amount Denied');

        _safeMint(msg.sender, _amount);
    }

    function withdraw() external nonReentrant {
        require(vault != address(0), 'Vault Invalid');
        payable(vault).transfer(address(this).balance);
    }
}