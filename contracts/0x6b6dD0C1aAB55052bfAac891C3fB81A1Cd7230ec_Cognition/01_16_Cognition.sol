// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract Cognition is ERC721, Ownable, PaymentSplitter {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private supply;
    uint256 private maxSupply = 364;
    bool public saleActive = false;
    string private baseTokenURI = "https://api.justinaversano.com/cognition/";

    mapping (address => uint256) public allowList;

    constructor(address[] memory payees, uint256[] memory shares) 
        ERC721("Cognition", "COG") 
        PaymentSplitter(payees, shares) payable {}

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    function toggleSale(bool active) public onlyOwner {
        saleActive = active;
    }

    function mint() public payable {
        require(saleActive,                       "Sale Not Active");
        require(supply.current() < maxSupply,     "Sold out!");
        uint256 price = 1000000000000000000; // 1 ETH
        require(msg.value == price,               "Ether sent is not correct");
        uint256 tokenId = allowList[msg.sender];
        require(tokenId > 0,                      "No mints allocated");
        require(tokenId <= maxSupply,             "TokenId out of range");

        require(!_exists(tokenId),                "TokenId already exists");
        allowList[msg.sender] = 0;
        supply.increment();
        _mint(msg.sender,tokenId);

    }

    function ownerMint(address to, uint256 tokenId) public onlyOwner {
        require(!_exists(tokenId),                "TokenId already exists");
        require(supply.current() < maxSupply,     "Sold out!");
        require(tokenId <= maxSupply,             "TokenId out of range");
        supply.increment();
        _mint(to, tokenId);
    }

    function batchMint(address to, uint256[] calldata ids) external onlyOwner {
        require(supply.current() + ids.length <= maxSupply, "Not enough Supply remaining to fulfill order");

        for(uint256 i= 0; i < ids.length; i++) {
            require(!_exists(ids[i]),             "One or more of your TokenIds already exists");
            supply.increment();
            _mint(to, ids[i]);
        }
    }

    function addToAllowList(address[] calldata users, uint256[] calldata ids) external onlyOwner {
        require(users.length == ids.length,       "Must submit equal counts of users and ids");
        for(uint256 i = 0; i < users.length; i++){
            allowList[users[i]] = ids[i];
        }
    }

    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner nor approved");
        _burn(tokenId);
        supply.decrement();
    }


    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
            if (_exists(currentTokenId)) {
                address currentTokenOwner = ownerOf(currentTokenId);
                if (currentTokenOwner == _owner) {
                    ownedTokenIds[ownedTokenIndex] = currentTokenId;
                    ownedTokenIndex++;
                }
            }
            currentTokenId++;
        }
        return ownedTokenIds;
    }

    function totalSupply() public view returns (uint256) {
        return supply.current();
    }    
}