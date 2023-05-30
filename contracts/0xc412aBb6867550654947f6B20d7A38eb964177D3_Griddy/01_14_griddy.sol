// contracts/GameItem.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Griddy is ERC721URIStorage, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    uint public constant maxPurchase = 10;
    uint public constant maxFreeMint = 1000;
    uint public constant maxNFTs = 5000;
    uint256 public constant purchasePrice = 5000000000000000; //0.005 ETH

    constructor() ERC721("GridironBattleships", "GRIDDYSHIPS") {}

    function withdraw(address _recipient) public payable onlyOwner {
        payable(_recipient).transfer(address(this).balance);
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function awardmint(address wallet)
        internal virtual 
        returns (uint256)
    {
        _tokenIds.increment();
        
        uint256 newItemId = _tokenIds.current();
        _mint(wallet, newItemId);
        _setTokenURI(newItemId, string(abi.encodePacked(
                "https://gridiron-nft.s3.us-east-2.amazonaws.com/",
                Strings.toString(newItemId),
                ".json"
            )));

        return newItemId;
    }

    function mintFree_First1kMints_MAX10perTXN(uint numberOfTokens) public {
        require(_tokenIds.current() <= maxFreeMint);
        require(numberOfTokens <= maxPurchase, "Can only mint 10 tokens at a time");
        require(_tokenIds.current().add(numberOfTokens) <= maxNFTs, "Purchase would exceed max supply of NFTs");

        for(uint i = 0; i < numberOfTokens; i++) {
            if (_tokenIds.current() < maxNFTs) {
                awardmint(msg.sender);
            }
        }
    }

    function mintBattleships_005_ETH_Each_MAX10perTXN(uint numberOfTokens) public payable {
        require(numberOfTokens <= maxPurchase, "Can only mint 10 tokens at a time");
        require(_tokenIds.current().add(numberOfTokens) <= maxNFTs, "Purchase would exceed max supply of NFTs");
        require(purchasePrice.mul(numberOfTokens) == msg.value, "Ether value sent is not correct");
        
        for(uint i = 0; i < numberOfTokens; i++) {
            if (_tokenIds.current() < maxNFTs) {
                awardmint(msg.sender);
            }
        }
    }

    function ownerMint(address wallet, uint numberOfTokens) public onlyOwner {
        require(numberOfTokens <= maxPurchase, "Can only mint 10 tokens at a time");
        require(_tokenIds.current().add(numberOfTokens) <= maxNFTs, "Purchase would exceed max supply of NFTs");
        
        for(uint i = 0; i < numberOfTokens; i++) {
            if (_tokenIds.current() < maxNFTs) {
                awardmint(wallet);
            }
        }
    }
}