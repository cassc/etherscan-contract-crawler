// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// @title:      Kitty Crypto Gang
// @twitter:    https://twitter.com/KittyCryptoGang
// @url:        https://www.kittycryptogang.com/

/*
 * █▄▀ █ ▀█▀ ▀█▀ █▄█   █▀▀ █▀█ █▄█ █▀█ ▀█▀ █▀█   █▀▀ ▄▀█ █▄░█ █▀▀
 * █░█ █ ░█░ ░█░ ░█░   █▄▄ █▀▄ ░█░ █▀▀ ░█░ █▄█   █▄█ █▀█ █░▀█ █▄█
 */

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract KCG is ERC721A, Ownable, ReentrancyGuard {
    using Address for address;
    using MerkleProof for bytes32[];

    // ===== Variables =====
    string public baseTokenURI;
    uint256 public mintPrice = 0.25 ether;
    uint256 public collectionSize = 7997;
    uint256 public whitelistMintMaxSupply = 5000;
    uint256 public reservedSize = 220;
    uint256 public maxItemsPerWallet = 2;
    uint256 public maxItemsPerTx = 2;

    bool public whitelistMintPaused = true;
    bool public raffleMintPaused = true;
    bool public publicMintPaused = true;

    bytes32 whitelistMerkleRoot;
    bytes32 rafflelistMerkleRoot;

    mapping(address => uint256) public whitelistMintedAmount;
    mapping(address => uint256) public raffleMintedAmount;

    // ===== Constructor =====
    constructor() ERC721A("Kitty Crypto Gang", "KCG", 10) {}

    // ===== Modifier =====
    function _onlySender() private view {
        require(msg.sender == tx.origin);
    }

    modifier onlySender {
        _onlySender();
        _;
    }

    // ===== Dev mint =====
    function devMint(uint256 amount) external onlySender onlyOwner {
        require(amount <= reservedSize, "Minting amount exceeds reserved size");
        require((totalSupply() + amount) <= collectionSize, "Sold out!");
        require(
            amount % maxBatchSize == 0,
            "Can only mint a multiple of the maxBatchSize"
        );
        uint256 numChunks = amount / maxBatchSize;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(msg.sender, maxBatchSize);
        }
    }

    // ===== Whitelist mint =====
    function kittyMint(bytes32[] memory proof) external payable onlySender nonReentrant {
        require(!whitelistMintPaused, "Whitelist mint is paused");
        require(
            isAddressWhitelisted(proof, msg.sender),
            "You are not eligible for a whitelist mint"
        );

        uint256 amount = _getMintAmount(msg.value);

        require(
            whitelistMintedAmount[msg.sender] + amount <= maxItemsPerWallet,
            "Minting amount exceeds allowance per wallet"
        );

        require(whitelistMintMaxSupply >= amount, "Whitelist mint is sold out");

        whitelistMintMaxSupply = whitelistMintMaxSupply - amount;

        whitelistMintedAmount[msg.sender] += amount;

        _mintWithoutValidation(msg.sender, amount);
    }

    // ===== Raffle mint =====
    function raffleMint(bytes32[] memory proof) external payable onlySender nonReentrant {
        require(!raffleMintPaused, "Raffle mint is paused");
        require(
            isAddressOnRafflelist(proof, msg.sender),
            "You are not eligible for a raffle mint"
        );

        uint256 amount = _getMintAmount(msg.value);

        require(
            raffleMintedAmount[msg.sender] + amount <= maxItemsPerWallet,
            "Minting amount exceeds allowance per wallet"
        );

        raffleMintedAmount[msg.sender] += amount;

        _mintWithoutValidation(msg.sender, amount);
    }

    // ===== Public mint =====
    function publicMint() external payable onlySender nonReentrant {
        require(!publicMintPaused, "Public mint is paused");

        uint256 amount = _getMintAmount(msg.value);

        require(
            amount <= maxItemsPerTx,
            "Minting amount exceeds allowance per tx"
        );

        _mintWithoutValidation(msg.sender, amount);
    }

    // ===== Helper =====
    function _getMintAmount(uint256 value) internal view returns (uint256) {
        uint256 remainder = value % mintPrice;
        require(remainder == 0, "Send a divisible amount of eth");

        uint256 amount = value / mintPrice;
        require(amount > 0, "Amount to mint is 0");
        require(
            (totalSupply() + amount) <= collectionSize - reservedSize,
            "Sold out!"
        );
        return amount;
    }

    function _mintWithoutValidation(address to, uint256 amount) internal {
        require((totalSupply() + amount) <= collectionSize, "Sold out!");
        _safeMint(to, amount);
    }

    function isAddressWhitelisted(bytes32[] memory proof, address _address)
        public
        view
        returns (bool)
    {
        return isAddressInMerkleRoot(whitelistMerkleRoot, proof, _address);
    }

    function isAddressOnRafflelist(bytes32[] memory proof, address _address)
        public
        view
        returns (bool)
    {
        return isAddressInMerkleRoot(rafflelistMerkleRoot, proof, _address);
    }

    function isAddressInMerkleRoot(
        bytes32 merkleRoot,
        bytes32[] memory proof,
        address _address
    ) internal pure returns (bool) {
        return proof.verify(merkleRoot, keccak256(abi.encodePacked(_address)));
    }

    // ===== Setter (owner only) =====
    function setReservedSize(uint256 _reservedSize) external onlyOwner {
        reservedSize = _reservedSize;
    }

    function setPublicMintPaused(bool _publicMintPaused) external onlyOwner {
        publicMintPaused = _publicMintPaused;
    }

    function setRaffleMintPaused(bool _raffleMintPaused) external onlyOwner {
        raffleMintPaused = _raffleMintPaused;
    }

    function setWhitelistMintPaused(bool _whitelistMintPaused)
        external
        onlyOwner
    {
        whitelistMintPaused = _whitelistMintPaused;
    }

    function setWhitelistMintMaxSupply(uint256 _whitelistMintMaxSupply)
        external
        onlyOwner
    {
        whitelistMintMaxSupply = _whitelistMintMaxSupply;
    }

    function setWhitelistMintMerkleRoot(bytes32 _whitelistMerkleRoot)
        external
        onlyOwner
    {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    function setRaffleMintMerkleRoot(bytes32 _rafflelistMerkleRoot)
        external
        onlyOwner
    {
        rafflelistMerkleRoot = _rafflelistMerkleRoot;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxItemsPerTx(uint256 _maxItemsPerTx) external onlyOwner {
        maxItemsPerTx = _maxItemsPerTx;
    }

    function setMaxItemsPerWallet(uint256 _maxItemsPerWallet) external onlyOwner {
        maxItemsPerWallet = _maxItemsPerWallet;
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    // ===== Withdraw to owner =====
    function withdrawAll() external onlyOwner onlySender nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed to send ether");
    }

    // ===== View =====
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        return
            string(abi.encodePacked(baseTokenURI, Strings.toString(tokenId)));
    }

    function walletOfOwner(address address_) public virtual view returns (uint256[] memory) {
        uint256 _balance = balanceOf(address_);
        uint256[] memory _tokens = new uint256[] (_balance);
        uint256 _index;
        uint256 _loopThrough = totalSupply();
        for (uint256 i = 0; i < _loopThrough; i++) {
            bool _exists = _exists(i);
            if (_exists) {
                if (ownerOf(i) == address_) { _tokens[_index] = i; _index++; }
            }
            else if (!_exists && _tokens[_balance - 1] == 0) { _loopThrough++; }
        }
        return _tokens;
    }
}