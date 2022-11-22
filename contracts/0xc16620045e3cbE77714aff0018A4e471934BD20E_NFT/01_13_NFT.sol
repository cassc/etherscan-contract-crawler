//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

import "hardhat/console.sol";

contract NFT is ERC721URIStorage {
    

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;

    address contractAddress;
    uint256 listingPrice = 0.001 ether;
    address owner;

    struct CreatedItem {
        uint tokenId;
        uint collectionId;
        address creator;
    }

    mapping(uint256 => CreatedItem) private idToCreatedItem;



    constructor(address marketplaceAddress) ERC721("Cryptonoit", "CRP"){
        contractAddress = marketplaceAddress;        
        owner = payable(msg.sender);
    }

    function getListingPrice() public view returns(uint256) {
        return listingPrice;
    }

    function updateListingPrice(uint256 _listPrice) public payable {

        require(owner == msg.sender, "Only owner can update the listing price");
        listingPrice = _listPrice;

    }



    function createToken(string memory tokenURI, uint256 collectionId) public payable returns  (uint){

        require(msg.value == listingPrice, "Please submit the asking price in order to complete the purchase");
        payable(owner).transfer(listingPrice);

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        setApprovalForAll(contractAddress, true);

        idToCreatedItem[newItemId] = CreatedItem(
            newItemId,
            collectionId,
            payable(msg.sender)
        );

        return newItemId;
    }

    function giveResaleApproval(uint256 tokenId) public {
         require( ownerOf(tokenId) == msg.sender, "You must own this NFT in order to resell it" ); 
         setApprovalForAll(contractAddress, true); 
         return; 
    }

    function fetchUserNftsCreator(address userAddress) public view returns (CreatedItem[] memory) {
        uint totalItemCount = _tokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        
        for(uint i = 0; i < totalItemCount; i++){
            if(idToCreatedItem[i + 1].creator == userAddress){                
                itemCount++;
            }
        }

        CreatedItem[] memory items = new CreatedItem[](itemCount);

        for(uint i = 0; i < totalItemCount; i++){
            if(idToCreatedItem[i + 1].creator == userAddress){
                uint currentId = idToCreatedItem[i + 1].tokenId;
                CreatedItem storage currentItem = idToCreatedItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex++;
            }
        }

        return items;

    }

    function getAllNftsWithCollectionId(uint256 collectionId) public view returns (CreatedItem[] memory){

        uint256 nftCount = _tokenIds.current();
        uint256 itemCount = 0;
        
        for(uint i = 0; i < nftCount; i++){
            if(idToCreatedItem[i+1].collectionId == collectionId){
                itemCount += 1;
            }
        }

        CreatedItem[] memory tokens = new CreatedItem[](itemCount);
        uint currentIndex = 0;

        for(uint i = 0; i < nftCount; i++){
            uint currentId = i + 1;
            if(idToCreatedItem[i+1].collectionId == collectionId){
                CreatedItem storage currentItem = idToCreatedItem[currentId];
                tokens[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return tokens;

    }

    function getNftWithTokenId(uint256 tokenId) public view returns (CreatedItem memory){
        return idToCreatedItem[tokenId];
    }
    


}