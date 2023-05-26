// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

// This contract represents the marketplace
contract IYKYKMarketplace is ERC1155Holder, ERC721Holder{
    
    address public owner;

    // A mapping from token ID to the price of the token in payment tokens
    mapping(uint256 => uint256) public erc1155Prices;
    mapping(uint256 => uint256) public erc721Prices;

    // A mapping from token ID to the number of tokens available for sale
    mapping(uint256 => uint256) public erc1155Inventory;
    mapping(uint256 => uint256) public erc721Inventory;

    // Token on sale
    struct Listing {
        uint256 tokenId;
        uint256 inventory;
        uint256 price;
        address contractAddress;
        bool isERC1155;
    }

    Listing[] public listings;

    event TokenPurchased(
        address purchaser,
        uint256 tokenId,
        uint256 price
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    constructor(){
        owner = msg.sender;
    }
    
    function getListings() public view returns (Listing[] memory) {
        return listings;
    }

    function findListingByTokenId(uint256 tokenId, address contractAddress) public view returns (bool, uint256) {
        for (uint256 i = 0; i < listings.length; i++) {
            if (listings[i].tokenId == tokenId && listings[i].contractAddress == contractAddress) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    // This function allows the owner of the marketplace to add a new ERC-1155 token
    // to the marketplace and set its price in payment tokens
    function addERC1155(uint256 tokenId, address contractAddress, uint256 amount, uint256 price) public onlyOwner {
        IERC1155 nftContract = IERC1155(contractAddress);
        require(nftContract.balanceOf(msg.sender, tokenId) >= amount, "Sender doesnt have the specified amount of tokens");
        nftContract.safeTransferFrom(msg.sender, address(this), tokenId, amount, '');
        // erc1155Prices[tokenId] = price;
        // erc1155Inventory[tokenId] = amount;

        (bool found, uint256 index) = findListingByTokenId(tokenId, contractAddress);
        if (!found) {
            Listing memory listing = Listing(tokenId, amount, price, contractAddress, true);
            listings.push(listing);
        } else {
            listings[index].inventory = listings[index].inventory + amount;
            listings[index].price = price;
        }

    }

    function removeERC1155(uint256 tokenId, address contractAddress, uint256 amount) public onlyOwner {
        IERC1155 nftContract = IERC1155(contractAddress);
        (bool found, uint256 index) = findListingByTokenId(tokenId, contractAddress);
        require(found, "Token not found");
        require(listings[index].inventory >= 1, "Insufficient inventory");
        listings[index].inventory = listings[index].inventory - amount;
        nftContract.safeTransferFrom(address(this), msg.sender, tokenId, amount, '');
    }

    function addERC721(uint256 tokenId, uint256 price, address contractAddress) public onlyOwner {
        IERC721 nftContract = IERC721(contractAddress);
        require(nftContract.ownerOf(tokenId) == msg.sender, "Sender does not own the token");
        (bool found, uint256 index) = findListingByTokenId(tokenId, contractAddress);
        if (!found) {
            Listing memory listing = Listing(tokenId, 1, price, contractAddress, false);
            listings.push(listing);
        } else {
            listings[index].inventory = 1;
            listings[index].price = price;
        }
        nftContract.safeTransferFrom(msg.sender, address(this), tokenId);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function removeERC721(uint256 tokenId, address contractAddress) public onlyOwner {
        (bool found, uint256 index) = findListingByTokenId(tokenId, contractAddress);
        require(found, "Token not found");
        require(listings[index].inventory >= 1, "Insufficient inventory");
        IERC721 nftContract = IERC721(contractAddress);
        listings[index].inventory = 0;
        nftContract.safeTransferFrom(address(this), msg.sender, tokenId);
    }

    function buyWithETH(uint256 tokenId, address contractAddress) public payable {
        (bool found, uint256 index) = findListingByTokenId(tokenId, contractAddress);
        require(found, "Token not found");
        require(listings[index].inventory > 0, "Insufficient inventory");
        require(msg.value >= listings[index].price, "Insufficient ETH sent");
        
        listings[index].inventory = listings[index].inventory - 1;

        if (listings[index].isERC1155) {
            IERC1155 nftContract = IERC1155(contractAddress);
            nftContract.safeTransferFrom(address(this), msg.sender, tokenId, 1, '');
        } else {
            IERC721 nftContract = IERC721(contractAddress);
            nftContract.safeTransferFrom(address(this), msg.sender, tokenId);
        }

        emit TokenPurchased(msg.sender, tokenId, listings[index].price);
    }
    
    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

}