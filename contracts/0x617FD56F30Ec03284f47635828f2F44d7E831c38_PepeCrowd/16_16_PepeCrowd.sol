// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/PullPayment.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract PepeCrowd is ERC721, Ownable, PullPayment, ReentrancyGuard {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    bool public isPresale = true;

    constructor() ERC721("PepeCrowd", "PepeCrowd") {}

    function _baseURI() 
        internal 
        pure 
        override 
        returns (string memory) 
    {
        return "https://pepecrowd.s3.eu-west-2.amazonaws.com/json/";
    }
     
    function tokenURI(uint256 tokenId) 
        public 
        view 
        virtual 
        override
        returns (string memory) 
    {
        _requireMinted(tokenId);
        return string(abi.encodePacked(super.tokenURI(tokenId),".json"));
    }

    function togglePresale() 
        external
        onlyOwner 
    {
        isPresale = !isPresale;
    }

    function mint(uint16 amount)
        external 
        payable 
    {
        require(
            (balanceOf(msg.sender) + amount) <= (isPresale ? 25 : 100),
            "OVER_LIMIT"
        );

        require(
            _tokenIdCounter.current() + amount <= 4999, 
            "OVER_SUPPLY"
        );

        require(
            msg.value >= (0.001 ether * amount), 
            "PAY_MORE"
        );
        
        _asyncTransfer(
            0x89C84873d4d0d30a7A1739cC8cC8F46e230933e6, 
            msg.value
        );

        for (uint16 i = 0; i < amount; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _mint(msg.sender, tokenId);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    } 

    function withdrawPayments(address payable payee) 
        public 
        nonReentrant 
        override 
    {
        return super.withdrawPayments(payee);
    }
}