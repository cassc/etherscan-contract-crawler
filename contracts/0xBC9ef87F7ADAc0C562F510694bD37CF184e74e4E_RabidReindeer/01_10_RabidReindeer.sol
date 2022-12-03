// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract RabidReindeer is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {

    // Max mint amount per wallet
    uint256 public MAX_MINT_PER_WALLET = 5;
    uint256 public MAX_MINT_PER_TRANSACTION = 5;

    // Sale status
    bool public enableSale = false;

    uint256 public maxSupply = 1_855;

    string public baseTokenURI;

    struct User {
        uint256 countSale;
    }

    mapping(address => User) public users;

    // Keep tracks of addresses that contribute 0.05 eth or more
    uint256 public DONATION_MINIMUM = 0.05 ether;
    address[] private donators;
    mapping(address => bool) public isDonator;

    constructor() ERC721A('Rabid Reindeer', 'RabidReindeer') {}

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenURI(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), '.json')) : '';
    }

    function setMaxSupply(uint _maxSupply) external onlyOwner {
        require(_maxSupply != maxSupply, 'Invalid supply');
        maxSupply = _maxSupply;
    }

    function setEnableSale(bool _enable) external onlyOwner {
        require(enableSale != _enable, 'Invalid status');
        enableSale = _enable;
    }

    function setMaxMintPerWallet(uint256 _limit) external onlyOwner {
        require(MAX_MINT_PER_WALLET != _limit, 'New limit is the same as the existing one');
        MAX_MINT_PER_WALLET = _limit;
    }

    function setMaxMintPerTransaction(uint256 _limit) external onlyOwner {
        require(MAX_MINT_PER_TRANSACTION != _limit, 'New limit is the same as the existing one');
        MAX_MINT_PER_TRANSACTION = _limit;
    }

    function getMints(address _wallet) external view returns (uint) {
        return _numberMinted(_wallet);
    }

    function getDonators() external view returns (address[] memory) {
        return donators;
    }

    function mintSale(uint256 _amount) external nonReentrant payable {
        require(enableSale, 'Sale is not enabled');
        require(tx.origin == msg.sender, 'Contract denied');
        require(_amount <= MAX_MINT_PER_TRANSACTION, 'Exceeds max mint per transaction');
        require(users[msg.sender].countSale + _amount <= MAX_MINT_PER_WALLET, 'Exceeds max mint per wallet');
        require(totalSupply() + _amount <= maxSupply, 'Exceeds maximum supply');

        if (msg.value >= DONATION_MINIMUM && !isDonator[msg.sender]) {
            donators.push(msg.sender);
            isDonator[msg.sender] = true;
        }

        _safeMint(msg.sender, _amount);
        users[msg.sender].countSale = users[msg.sender].countSale + _amount;
    }

    function ownerMint(uint _amount) external nonReentrant onlyOwner {
        require(tx.origin == msg.sender, 'Contract Denied');
        require(totalSupply() + _amount <= maxSupply, 'Exceeds maximum supply');

        _safeMint(msg.sender, _amount);
    }

    function withdraw() external nonReentrant onlyOwner {
        require(tx.origin == msg.sender, 'Contract denied');
        uint256 balance = address(this).balance;
        require(balance > 0, 'Balance is 0');
        payable(msg.sender).transfer(balance);
    }

    function setApprovalForAll(address operator, bool approved)
        public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override payable onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public override payable onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public override payable onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public override payable onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}