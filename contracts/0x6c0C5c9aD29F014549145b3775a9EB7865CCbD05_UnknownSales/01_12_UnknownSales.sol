// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./UnknownSociety.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract UnknownSales is Ownable, ReentrancyGuard {
    UnknownSociety unk;
    enum MintType{ HOLDER, WHITELIST, PUBLIC }
 
    address private signer;
    uint256 private holderPrice = 0.024 ether;
    uint256 private wlPrice = 0.036 ether;
    uint256 private publicPrice = 0.045 ether;
        
    uint256 public maxPerWallet = 2;
    mapping(address => uint256) public whitelistMinted;
    mapping(address => uint256) public holderMinted;
    mapping(address => uint256) public publicMinted;

    constructor(UnknownSociety _unk) {
        signer = msg.sender;
        unk = _unk;
    }

    function setPrice(uint256 _holderPrice, uint256 _wlPrice, uint256 _publicPrice) external onlyOwner {
        holderPrice = _holderPrice;
        wlPrice = _wlPrice;
        publicPrice = _publicPrice;
    }

    function setMaxPerWallet(uint256 _newMaxPerwallet) external onlyOwner {
        maxPerWallet = _newMaxPerwallet;
    }

    function ownerMint(UnknownSociety.MintType _type, address receiver, uint256 amount)
    external
    onlyOwner
    {
        unk.ownerMint(_type, receiver, amount);
    }

    function holderMint(uint256 amount)
    external
    payable 
    validateMint(MintType.WHITELIST, amount)
    nonReentrant
    {
        require(unk.balanceOf(msg.sender) > 0, "You are not a holder");
        holderMinted[msg.sender] += amount;
        unk.ownerMint(UnknownSociety.MintType.WHITELIST, msg.sender, amount);
    }

    function whitelistMint(bytes calldata signature, uint256 amount)
    external
    payable 
    validateMint(MintType.WHITELIST, amount)
    nonReentrant
    {
        require(_isVerifiedSignature(signature), "Invalid Signature");
        whitelistMinted[msg.sender] += amount;
        unk.ownerMint(UnknownSociety.MintType.WHITELIST, msg.sender, amount);
    }

    function publicMint(uint256 amount)
    external
    payable 
    validateMint(MintType.PUBLIC, amount)
    nonReentrant
    {
        publicMinted[msg.sender] += amount;
        unk.ownerMint(UnknownSociety.MintType.WHITELIST, msg.sender, amount);
    }

    function _isVerifiedSignature(bytes calldata signature)
    internal
    view
    returns (bool)
    {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                bytes32(uint256(uint160(msg.sender)))
            )
        );
        return ECDSA.recover(digest, signature) == signer;
    }

    function transferCollectionOwner(address newOwner) external onlyOwner {
        unk.transferOwnership(newOwner);
    }

    function migrateBalance() external onlyOwner {
        unk.withdraw();
    }

    function withdraw(uint256 amount, address receiver) external onlyOwner {
        payable(receiver).transfer(amount);
    }

    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    modifier validateMint(MintType _type, uint256 amount) {
        uint256 price = publicPrice;
        
        if (_type == MintType.HOLDER) {
            price = holderPrice;
            require(holderMinted[msg.sender] + amount < maxPerWallet + 1, "Max mint per wallet");
        } else if (_type == MintType.WHITELIST) {
            price = holderPrice;
            require(whitelistMinted[msg.sender] + amount < maxPerWallet + 1, "Max mint per wallet");
        } else {
            require(publicMinted[msg.sender] + amount < maxPerWallet + 1, "Max mint per wallet");
        }
        
        require(msg.value >= price * amount, "Ether value sent is not correct");
        _;
    }
}