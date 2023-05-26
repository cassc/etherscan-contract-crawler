// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract ERC5050 is ERC721A, Ownable, ReentrancyGuard {
    // limits
    uint256 public maxPerTransaction = 10;
    uint256 public maxPerWallet = 40;
    uint256 public maxTotalSupply = 8000;
    uint256 public chanceFreeMintsAvailable = 3500;
    uint256 public freeMintsAvailable = 1000;

    // sale states
    bool public isPublicLive = false;
    bool public isWhitelistLive = false;

    // price
    uint256 public mintPrice = 0.005 ether;

    // whitelist config
    bytes32 private merkleTreeRoot;
    mapping(address => uint256) public whitelistMintsPerWallet;

    // metadata
    string public baseURI;

    // config
    mapping(address => uint256) public mintsPerWallet;
    address private withdrawAddress = address(0);

    constructor(string memory name, string memory symbol) ERC721A(name, symbol) {}

    function mintPublic(uint256 _amount) external payable nonReentrant {
        require(isPublicLive, "Sale not live");
        require(_amount > 0, "You must mint at least one");
        require(totalSupply() + _amount <= maxTotalSupply, "Exceeds total supply");
        require(_amount <= maxPerTransaction, "Exceeds max per transaction");
        require(mintsPerWallet[_msgSender()] + _amount <= maxPerWallet, "Exceeds max per wallet");

        // 1 guaranteed free per wallet
        uint256 pricedAmount = freeMintsAvailable > 0 && mintsPerWallet[_msgSender()] == 0
            ? _amount - 1
            : _amount;

        if (pricedAmount < _amount) {
            freeMintsAvailable = freeMintsAvailable - 1;
        }

        require(mintPrice * pricedAmount <= msg.value, "Not enough ETH sent for selected amount");

        uint256 refund = chanceFreeMintsAvailable > 0 && pricedAmount > 0 && isFreeMint()
            ? pricedAmount * mintPrice
            : 0;

        if (refund > 0) {
            chanceFreeMintsAvailable = chanceFreeMintsAvailable - pricedAmount;
        }

        // sends needed ETH back to minter
        payable(_msgSender()).transfer(refund);

        mintsPerWallet[_msgSender()] = mintsPerWallet[_msgSender()] + _amount;

        _safeMint(_msgSender(), _amount);
    }

    function mintWhitelist(bytes32[] memory _proof) external nonReentrant {
        require(isWhitelistLive, "Whitelist sale not live");
        require(totalSupply() + 1 <= maxTotalSupply, "Exceeds total supply");
        require(whitelistMintsPerWallet[_msgSender()] < 1, "Exceeds max whitelist mints per wallet");
        require(MerkleProof.verify(_proof, merkleTreeRoot, keccak256(abi.encodePacked(_msgSender()))), "Invalid proof");

        whitelistMintsPerWallet[_msgSender()] = 1;

        _safeMint(_msgSender(), 1);
    }

    function mintPrivate(address _receiver, uint256 _amount) external onlyOwner {
        require(totalSupply() + _amount <= maxTotalSupply, "Exceeds total supply");
        _safeMint(_receiver, _amount);
    }

    function flipPublicSaleState() external onlyOwner {
        isPublicLive = !isPublicLive;
    }

    function flipWhitelistSaleState() external onlyOwner {
        isWhitelistLive = !isWhitelistLive;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function isFreeMint() internal view returns (bool) {
        return (uint256(keccak256(abi.encodePacked(
            tx.origin,
            blockhash(block.number - 1),
            block.timestamp,
            _msgSender()
        ))) & 0xFFFF) % 2 == 0;
    }

    function withdraw() external onlyOwner {
        require(withdrawAddress != address(0), "No withdraw address");
        payable(withdrawAddress).transfer(address(this).balance);
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setFreeMintsAvailable(uint256 _freeMintsAvailable) external onlyOwner {
        freeMintsAvailable = _freeMintsAvailable;
    }

    function setChanceFreeMintsAvailable(uint256 _chanceFreeMintsAvailable) external onlyOwner {
        chanceFreeMintsAvailable = _chanceFreeMintsAvailable;
    }

    function setMaxTotalSupply(uint256 _maxTotalSupply) external onlyOwner {
        maxTotalSupply = _maxTotalSupply;
    }

    function setMaxPerTransaction(uint256 _maxPerTransaction) external onlyOwner {
        maxPerTransaction = _maxPerTransaction;
    }

    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setWithdrawAddress(address _withdrawAddress) external onlyOwner {
        withdrawAddress = _withdrawAddress;
    }

    function setMerkleTreeRoot(bytes32 _merkleTreeRoot) external onlyOwner {
        merkleTreeRoot = _merkleTreeRoot;
    }
}