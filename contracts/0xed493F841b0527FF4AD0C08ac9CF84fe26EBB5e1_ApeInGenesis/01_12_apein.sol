// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract ApeInGenesis is ERC1155Supply, Ownable {
    using ECDSA for bytes32;

    uint256 constant APE_RESERVED = 100;
    uint256 constant APE_PRIVATE = 2900;
    uint256 constant APE_MAX = 3000;
    uint256 constant MINT_PRICE = 0.25 ether;
    address constant TEAM_ADDRESS = 0xd97b398267C112eDB024018d6a1Eb84F505d699a;

    mapping(string => bool) private _nonces;
    address private _signerAddress = 0xEF1f611A5D34ee2ceC474AbC212d625362329BC0;

    mapping(address => bool) public presalePurchased;
    uint256 public publicCounter;
    uint256 public privateCounter;
    bool public mintedReserve;
    bool public publicLive;
    bool public presaleLive;

    constructor() ERC1155("https://ipfs.io/ipfs/QmSbBvEWdvQz189Nb5FioPaCBqbSPnfNkGqCzNeGXEp5EG/{id}") {}

    function verifyTransaction(address sender, uint256 amount, string memory nonce, bytes memory signature) private view returns(bool) {
        bytes32 hash = keccak256(abi.encodePacked(sender, amount, nonce));
        return _signerAddress == hash.recover(signature);
    }
    
    function verifyPresale(address sender, bytes memory signature) private view returns(bool) {
        bytes32 hash = keccak256(abi.encodePacked(sender));
        return _signerAddress == hash.recover(signature);
    }

    function reserve() external onlyOwner {
        require(!mintedReserve, "RESERVES_ALREADY_MINTED");

        mintedReserve = true;
        _mint(TEAM_ADDRESS, 1, APE_RESERVED, "");
    }

    function presale(bytes memory signature) external payable {
        require(presaleLive, "NOT_RELEASED");
        require(totalSupply(1) < APE_MAX, "SOLD_OUT");
        require(!presalePurchased[msg.sender], "ALREADY_BOUGHT");
        require(privateCounter + 1 <= APE_PRIVATE, "MAX_PRIVATE_SALE");
        require(verifyPresale(msg.sender, signature), "INVALID_TRANSACTION");
        require(msg.value >= MINT_PRICE, "INSUFFICIENT_ETH_SENT");

        presalePurchased[msg.sender] = true;
        privateCounter++;
        _mint(msg.sender, 1, 1, "");
    }

    function purchase(uint256 amount, bytes memory signature, string memory nonce) external payable {
        require(publicLive, "NOT_RELEASED");
        require(!_nonces[nonce], "NONCE_CONSUMED");
        require(totalSupply(1) < APE_MAX, "SOLD_OUT");
        require(publicCounter + amount <= APE_MAX - privateCounter - APE_RESERVED, "MAX_PUBLIC_SALE");
        require(verifyTransaction(msg.sender, amount, nonce, signature), "INVALID_TRANSACTION");
        require(msg.value >= amount * MINT_PRICE, "INSUFFICIENT_ETH_SENT");

        _nonces[nonce] = true;
        publicCounter += amount;
        _mint(msg.sender, 1, amount, "");
    }

    function setSignerAddress(address signer) external onlyOwner {
        _signerAddress = signer;
    }

    function withdraw() external onlyOwner {
        payable(TEAM_ADDRESS).transfer(address(this).balance);
    }

    function togglePublicSale() external onlyOwner {
        publicLive = !publicLive;
    }

    function togglePreSale() external onlyOwner {
        presaleLive = !presaleLive;
    }
}