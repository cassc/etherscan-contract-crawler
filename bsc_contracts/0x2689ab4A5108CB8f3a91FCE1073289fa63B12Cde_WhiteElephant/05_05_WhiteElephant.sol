// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/*
Gift exchange contract.
User enters by sending a crate,
then user finds their time to select gift,
then after the giftStart block passes,
users begin to select their crates.
*/
contract WhiteElephant is Ownable {
    uint public giftStart;

    mapping (address => uint) public entry;
    
    mapping (address => mapping(uint => bool)) public gifts;

    mapping (address => bool) public eligible;

//giftStart is the block when people can begin claiming gifts.
    constructor(uint giftStart_) {
        giftStart = giftStart_;
    }

//User must approve the NFT first
//Then this function sends the NFT and gets the user a block to claim one
    function enter(address nft, uint id) external {
        require(tx.origin == msg.sender, "WhiteElephant::enter no contracts allowed.");
        require(entry[msg.sender] == 0, "WhiteElephant::enter already entered");
        require(block.number < giftStart, "WhiteElephant::enter too late to enter; gifts are being claimed already.");
        require(eligible[nft], "WhiteElephant::enter not an eligible NFT.");
        gifts[nft][id] = true;
        entry[msg.sender] = uint(keccak256(abi.encodePacked(msg.sender, block.coinbase, block.timestamp)))%28800 + giftStart;
        IERC721(nft).transferFrom(msg.sender, address(this), id);
    }

//Users can claim one of the NFTs that this contract holds.
//Users must wait until their time, which is set in the previous function.
    function claimGift(address nft, uint id) external {
        require(entry[msg.sender] < block.number, "WhiteElephant::claimGift not your turn!");
        require(entry[msg.sender] >= giftStart, "WhiteElephant::claimGift not a valid entry.");
        require(gifts[nft][id], "WhiteElephant::claimGift that gift was already claimed.");
        gifts[nft][id] = false;
        entry[msg.sender] = 0;
        IERC721(nft).transferFrom(address(this), msg.sender, id);
    }

//Contract owner sets the eligible NFT types ahead of time.
    function setEligible(address nftContract, bool value) external onlyOwner {
        eligible[nftContract] = value;
    }
}