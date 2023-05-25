// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

contract TheHighSociety is ERC721A, Ownable, ReentrancyGuard {

    // Merkle root for pre-sale
    bytes32 public merkleRootBatchOne;
    bytes32 public merkleRootBatchTwo;

    // Max mint amount per wallet
    uint256 public MAX_MINT_PER_WALLET_PRESALE_BATCH_ONE = 1;
    uint256 public MAX_MINT_PER_WALLET_PRESALE_BATCH_TWO = 6;
    uint256 public MAX_MINT_PER_WALLET_SALE = 10;

    // Sale status
    bool public enablePresaleBatchOne = false;
    bool public enablePresaleBatchTwo = false;
    bool public enableSale = false;

    // Price
    uint256 public PRICE_PRESALE_BATCH_TWO = 0.1 ether;
    uint256 public PRICE_SALE = 0.1 ether;

    uint256 public maxSupply = 10_000;

    string public baseTokenURI;

    // Track the number of NFT minted for each sale round
    struct User {
        uint256 countPresaleBatchOne;
        uint256 countPresaleBatchTwo;
        uint256 countSale;
    }

    mapping(address => User) public users;

    constructor() ERC721A("TheHighSociety", "TheHighSociety") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenURI(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : '';
    }

    function setMaxSupply(uint _maxSupply) external onlyOwner {
        require(_maxSupply != maxSupply, 'Invalid supply');
        maxSupply = _maxSupply;
    }

    function setMerkleRootBatchOne(bytes32 _merkleRoot) external onlyOwner {
        merkleRootBatchOne = _merkleRoot;
    }

    function setMerkleRootBatchTwo(bytes32 _merkleRoot) external onlyOwner {
        merkleRootBatchTwo = _merkleRoot;
    }

    function setPricePresaleBatchTwo(uint256 _price) external onlyOwner {
        require(PRICE_PRESALE_BATCH_TWO != _price, "Invalid price");
        PRICE_PRESALE_BATCH_TWO = _price;
    }

    function setPriceSale(uint256 _price) external onlyOwner {
        require(PRICE_SALE != _price, "Invalid price");
        PRICE_SALE = _price;
    }

    function setEnablePresaleBatchOne(bool _enable) external onlyOwner {
        require(enablePresaleBatchOne != _enable, "Invalid status");
        enablePresaleBatchOne = _enable;
    }

    function setEnablePresaleBatchTwo(bool _enable) external onlyOwner {
        require(enablePresaleBatchTwo != _enable, "Invalid status");
        enablePresaleBatchTwo = _enable;
    }

    function setEnableSale(bool _enable) external onlyOwner {
        require(enableSale != _enable, "Invalid status");
        enableSale = _enable;
    }

    function setMaxMintPerWalletPresaleBatchOne(uint256 _limit) external onlyOwner {
        require(MAX_MINT_PER_WALLET_PRESALE_BATCH_ONE != _limit, "New limit is the same as the existing one");
        MAX_MINT_PER_WALLET_PRESALE_BATCH_ONE = _limit;
    }

    function setMaxMintPerWalletPresaleBatchTwo(uint256 _limit) external onlyOwner {
        require(MAX_MINT_PER_WALLET_PRESALE_BATCH_TWO != _limit, "New limit is the same as the existing one");
        MAX_MINT_PER_WALLET_PRESALE_BATCH_TWO = _limit;
    }

    function setMaxMintPerWalletSale(uint256 _limit) external onlyOwner {
        require(MAX_MINT_PER_WALLET_SALE != _limit, "New limit is the same as the existing one");
        MAX_MINT_PER_WALLET_SALE = _limit;
    }

    function getMints(address _wallet) external view returns (uint) {
        return _numberMinted(_wallet);
    }

    function mintPresaleBatchOne(bytes32[] calldata _merkleProof, uint256 _amount) external nonReentrant {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        require(enablePresaleBatchOne, "Pre-sale batch one is not enabled");
        require(tx.origin == msg.sender, "Contract denied");
        require(totalSupply() + _amount <= maxSupply, "Exceeds maximum supply");
        require(
            users[msg.sender].countPresaleBatchOne + _amount <= MAX_MINT_PER_WALLET_PRESALE_BATCH_ONE,
            "Exceeds max mint limit per wallet");
        require(MerkleProof.verify(_merkleProof, merkleRootBatchOne, leaf), "Proof Invalid");

        _safeMint(msg.sender, _amount);
        users[msg.sender].countPresaleBatchOne = users[msg.sender].countPresaleBatchOne + _amount;
    }

    function mintPresaleBatchTwo(bytes32[] calldata _merkleProof, uint256 _amount) external nonReentrant payable {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        require(enablePresaleBatchTwo, "Pre-sale batch two is not enabled");
        require(totalSupply() + _amount <= maxSupply, "Exceeds maximum supply");
        require(tx.origin == msg.sender, "Contract denied");
        require(
            users[msg.sender].countPresaleBatchTwo + _amount <= MAX_MINT_PER_WALLET_PRESALE_BATCH_TWO,
            "Exceeds max mint limit per wallet");
        require(MerkleProof.verify(_merkleProof, merkleRootBatchTwo, leaf), "Proof Invalid");
        require(msg.value >= PRICE_PRESALE_BATCH_TWO * _amount, "Value below price");

        _safeMint(msg.sender, _amount);
        users[msg.sender].countPresaleBatchTwo = users[msg.sender].countPresaleBatchTwo + _amount;
    }

    function mintSale(uint256 _amount) external nonReentrant payable {
        require(enableSale, "Sale is not enabled");
        require(tx.origin == msg.sender, "Contract denied");
        require(totalSupply() + _amount <= maxSupply, "Exceeds maximum supply");
        require(
            users[msg.sender].countSale + _amount <= MAX_MINT_PER_WALLET_SALE,
            "Exceeds max mint limit per wallet"
        );
        require(msg.value >= PRICE_SALE * _amount, "Value below price");

        _safeMint(msg.sender, _amount);
        users[msg.sender].countSale = users[msg.sender].countSale + _amount;
    }

    function ownerMint(uint _amount) external nonReentrant onlyOwner {
        require(tx.origin == msg.sender, 'Contract Denied');
        require(totalSupply() + _amount <= maxSupply, "Exceeds maximum supply");

        _safeMint(msg.sender, _amount);
    }

    function withdraw() external nonReentrant onlyOwner {
        require(tx.origin == msg.sender, 'Contract denied');
        uint256 balance = address(this).balance;
        require(balance > 0, "Balance is 0");
        payable(msg.sender).transfer(balance);
    }
}