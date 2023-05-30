// SPDX-License-Identifier: UNLICENSED

// Code by zipzinger and cmtzco
// DEFIBOYS
// defiboys.com

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./Nft.sol";

contract NftManager is Ownable {
    mapping(address => bool) public approvedContracts;

    function swap(address _recipient, uint256 _tokenID) external {
        require(
            approvedContracts[msg.sender],
            "Run setApprovedContract for NFT Contract"
        );
        Nft(msg.sender).nftManagerPerformSwap(_recipient, _tokenID);
    }

    function setApprovedContract(address addr, bool status) external onlyOwner {
        approvedContracts[addr] = status;
    }
}