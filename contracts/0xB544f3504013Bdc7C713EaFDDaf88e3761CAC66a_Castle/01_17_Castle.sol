// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./NFT_Goose.sol";
import "./Planting.sol";

contract Castle is Ownable, ReentrancyGuard {
    ERC20 public token;
    NFT_Goose public nft;
    Planting public planting;

    mapping(address => uint256) public userLooted;

    event LootingSuccessful(address user, uint256 choice);

    constructor(address _plantingAddress, address _nftAddress) {
        planting = Planting(_plantingAddress);
        nft = NFT_Goose(_nftAddress);
    }

    function setTokenAddress(address _tokenAddress) public onlyOwner {
        token = ERC20(_tokenAddress);
    }

    function loot(uint256 _choice) public nonReentrant {
        require(_choice == 1 || _choice == 2, "Invalid choice");
        require(userLooted[msg.sender] == 0, "This user already looted the castle.");
        require(planting.getPlant(msg.sender).phase == 4, "The user is not at the last planting phase.");
        require(planting.currentPhaseFinished(msg.sender), "The user has not finished its planting phase");

        userLooted[msg.sender] = _choice;

        if (_choice == 1) { // Treasure
            token.transfer(msg.sender, 1);
        } else if (_choice == 2) { // Goose
            nft.mintForUser(msg.sender);
        }

        emit LootingSuccessful(msg.sender, _choice);
    }
}