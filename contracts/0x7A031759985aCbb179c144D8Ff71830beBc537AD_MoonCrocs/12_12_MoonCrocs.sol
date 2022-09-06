// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";

contract MoonCrocs is ERC721A, Ownable, ReentrancyGuard, PaymentSplitter {
    using Strings for uint256;
    using MerkleProof for bytes32;

    string public baseURI;
    uint256 public mintPrice = 0.04 ether;
    uint256 public wlMintPrice = 0.03 ether;
    uint256 public maxPerTransaction;
    uint256 public maxPerWallet;
    uint256 public maxPerWlWallet;
    uint256 public maxTotalSupply;
    uint256 public freeMints;
    bool public isPublicLive = false;
    bool public isWhitelistLive = false;
    bytes32 public merkleTreeRoot;
    mapping(address => uint256) public whitelistMintsPerWallet;    
    mapping(address => uint256) public mintsPerWallet;

    
    constructor(
        address[] memory _payees,
        uint256[] memory _shares,
        uint256 _maxPerWallet,
        uint256 _maxPerWlWallet,
        uint256 _maxPerTransaction,
        uint256 _maxTotalSupply,
        uint256 _freeMints
    )
    ERC721A("mooncrocs", "CROC")
    PaymentSplitter(_payees, _shares) {
        maxPerWallet = _maxPerWallet;
        maxPerWlWallet = _maxPerWlWallet;
        maxPerTransaction = _maxPerTransaction;
        maxTotalSupply = _maxTotalSupply;
        freeMints = _freeMints;
    }


    function mintPublic(uint256 _amount) external payable nonReentrant {
        require(isPublicLive, "Sale not live");
        require(totalSupply() + _amount <= maxTotalSupply, "Exceeds total supply");
        require(_amount <= maxPerTransaction, "Exceeds max per transaction");
        require(mintPrice * _amount <= msg.value, "Not enough ETH sent for selected amount");
        uint256 walletMints = mintsPerWallet[_msgSender()];
        require(walletMints + _amount <= maxPerWallet, "Exceeds max mints per wallet");

        uint256 refund = isFreeMint() && freeMints - _amount >= 0 ? _amount * mintPrice : 0;

        if (refund > 0) {
            freeMints = freeMints - _amount;
            Address.sendValue(payable(_msgSender()), refund);
        }

        mintsPerWallet[_msgSender()] = walletMints + _amount;

        _safeMint(_msgSender(), _amount);
    }

    function mintWhitelist(bytes32[] memory _proof, uint256 _amount) external payable nonReentrant {
        require(isWhitelistLive, "Whitelist sale not live");
        require(wlMintPrice * _amount <= msg.value, "Not enough ETH sent for selected amount");
        require(totalSupply() + _amount <= maxTotalSupply, "Exceeds total supply");
        uint256 wlMints = whitelistMintsPerWallet[_msgSender()];
        require(wlMints + _amount <= maxPerWlWallet, "Exceeds max whitelist mints per wallet");
        require(MerkleProof.verify(_proof, merkleTreeRoot, keccak256(abi.encodePacked(_msgSender()))), "Invalid proof");

        uint256 refund = isFreeMint() && freeMints - _amount >= 0 ? _amount * wlMintPrice : 0;

        if (refund > 0) {
            freeMints = freeMints - _amount;
            Address.sendValue(payable(_msgSender()), refund);
        }

        whitelistMintsPerWallet[_msgSender()] = wlMints + _amount;
        _safeMint(_msgSender(), _amount);
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

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setWlMintPrice(uint256 _mintPrice) external onlyOwner {
        wlMintPrice = _mintPrice;
    }

    function setFreeMints(uint256 _amount) external onlyOwner {
        freeMints = _amount;
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

    function setMaxPerWlWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWlWallet = _maxPerWallet;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMerkleTreeRoot(bytes32 _merkleTreeRoot) external onlyOwner {
        merkleTreeRoot = _merkleTreeRoot;
    }

}