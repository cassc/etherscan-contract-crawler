// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "contracts/ERC5050.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract TenjinGenesis is ERC5050 {

    bool private _revealed = false;

    constructor(string memory name_, string memory symbol_) ERC5050(name_, symbol_) {
        maxPerTransaction = 2;
        maxPerWallet = 2;
        maxTotalSupply = 3888;
        chanceFreeMintsAvailable = 3888;
        freeMintsAvailable = 0;
        isWhitelistLive = true;
        mintPrice = 0.005 ether;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if(_revealed){
            return string(abi.encodePacked(super.tokenURI(tokenId), '.json'));
        }

        return _baseURI();
    }

    function mintWhitelist(uint256 _amount, bytes32[] memory _proof) external payable nonReentrant {
        require(isWhitelistLive, "Whitelist sale not live");
        require(_amount > 0, "You must mint at least one");
        require(_amount <= maxPerTransaction, "Exceeds max per transaction");
        require(totalSupply() + _amount <= maxTotalSupply, "Exceeds total supply");
        require(mintsPerWallet[_msgSender()] < maxPerWallet, "Exceeds max whitelist mints per wallet");
        require(MerkleProof.verify(_proof, merkleTreeRoot, toBytes32(msg.sender)) == true, "Invalid proof");

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

    function reveal(string memory _newBaseURI) external onlyOwner {
        _revealed = true;
        baseURI = _newBaseURI;
    }
}