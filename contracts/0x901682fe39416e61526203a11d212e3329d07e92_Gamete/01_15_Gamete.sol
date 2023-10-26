// SPDX-License-Identifier: Unlicense

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Gamete is ERC721, Ownable {
    mapping (uint => uint) public itemCounts;
    mapping (uint => uint) public nthOfItem;
    mapping (uint => uint) public tokenIdToItemId;
    mapping (uint => uint) public numOfItemsRemaining;
    uint public numItemIds;
    address payable withdrawalAddress;
    bool live = false;

    constructor(string memory baseURI, uint[] memory itemIds, uint[] memory numRemaining, address payable addr) ERC721("Gamete","GAMETE")  {
        require(itemIds.length == numRemaining.length, "Invalid remaining length");
        setBaseURI(baseURI);
        numItemIds = itemIds.length;
        for (uint i = 0; i < itemIds.length; i++) {
            numOfItemsRemaining[itemIds[i]] = numRemaining[i];
        }
        withdrawalAddress = addr;

        for (uint i = 0; i < 5; i++) {
            mint(10);
        }
        live = true;
    }

    function mint(uint itemId) public payable {
        require(!live || msg.value >= calculatePrice(itemId), "Insufficient ether sent");
        require(itemId > 0 && itemId <= numItemIds, "Invalid item ID");
        require(numOfItemsRemaining[itemId] > 0, "No more of this item available");
        uint tokenId = totalSupply() + 1;
        itemCounts[itemId]++;
        nthOfItem[tokenId] = itemCounts[itemId];
        tokenIdToItemId[tokenId] = itemId;
        numOfItemsRemaining[itemId]--;   
        _safeMint(msg.sender, tokenId);
        if (live) {
            (bool success, ) = withdrawalAddress.call{value: msg.value}("");
            require(success, "Payment forwarding failed");
        }
    }

    function calculatePrice(uint itemId) public view returns (uint) {
        uint currentAmount = itemCounts[itemId];
        if (itemId == 10) {
            return 0.125 ether;
        }
        else if (currentAmount >= 8) {
            return 10.24 ether;
        }
        else if (currentAmount >= 5) {
            return 5.12 ether;
        }
        else if (currentAmount >= 3) {
            return 2.56 ether;
        }
        else if (currentAmount >= 2) {
            return 1.28 ether;
        }
        else if (currentAmount >= 0) {
            return 0.64 ether;
        }
    }

    function getAllPrices() external view returns (uint[] memory) {
        uint[] memory prices = new uint[](numItemIds);
        for (uint i = 0; i < numItemIds; i++) {
            prices[i] = calculatePrice(i + 1);
        }
        return prices;
    }

    function tokensOfOwner(address owner) public view returns(uint[] memory) {
        uint tokenCount = balanceOf(owner);
        if (tokenCount == 0) {
            return new uint[](0);
        } else {
            uint[] memory result = new uint[](tokenCount);
            for (uint i = 0; i < tokenCount; i++) {
                result[i] = tokenOfOwnerByIndex(owner, i);
            }
            return result;
        }
    }

    function getItemsOfOwner(address owner) public view returns (uint[] memory) {
        uint[] memory tokens = tokensOfOwner(owner);
        uint[] memory itemIds = new uint[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            itemIds[i] = tokenIdToItemId[tokens[i]];
        }
        return itemIds;
    }

    function addressOwnsItemId(address owner, uint itemId) public view returns (bool){
        uint[] memory itemIds = getItemsOfOwner(owner);
        for (uint i = 0; i < itemIds.length; i++) {
            if (itemIds[i] == itemId) {
                return true;
            }
        }
        return false;
    }

    function getRemainingItems() public view returns (uint[] memory) {
        uint[] memory amounts = new uint[](numItemIds);
        for (uint i = 0; i < numItemIds; i++) {
            amounts[i] = numOfItemsRemaining[i + 1];
        }
        return amounts;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }
}