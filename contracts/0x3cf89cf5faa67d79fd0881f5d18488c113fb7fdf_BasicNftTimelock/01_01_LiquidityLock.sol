// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;


interface NFT {
    function ownerOf(uint256 tokenId) external view returns (address);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract BasicNftTimelock {
    address public nftContract;
    uint256 public tokenId;
    address public beneficiary;
    uint256 public releaseTime;

    constructor() {}

    function set(address nftContract_, uint256 tokenId_, address beneficiary_, uint256 releaseTime_) public {
        require(nftContract == address(0), "NFT info already set");
        require(releaseTime_ > block.timestamp, "Release time has to be in the future");
        
        nftContract = nftContract_;
        tokenId = tokenId_;
        beneficiary = beneficiary_;
        releaseTime = releaseTime_;
    }

    function release() public {
        NFT nftInt = NFT(nftContract);

        require(block.timestamp >= releaseTime, "Current time is before release time");
        require(nftInt.ownerOf(tokenId) == address(this), "No NFT to release");

        nftInt.transferFrom(address(this), beneficiary, tokenId);
    }
}