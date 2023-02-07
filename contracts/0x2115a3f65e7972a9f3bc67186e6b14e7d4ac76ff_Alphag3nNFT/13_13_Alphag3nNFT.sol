// SPDX-License-Identifier: MIT
// Copyright Siddhartha Chatterjee
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract Alphag3nNFT is ERC721URIStorage, Ownable {
    uint256 public tokenCount = 0;

    enum Rank {
        None,
        Purple,
        Bronze,
        Silver,
        Gold,
        Diamond
    }

    struct User {
        Rank rank;
        uint256[] tokens;
    }

    mapping(address => User) private users;

    mapping(address => bool) private admins;

    mapping(Rank => uint256) private costs;

    constructor() ERC721("ALPHAG3NNFT", "G3N") {
        tokenCount = 0;
        costs[Rank.Purple] = 0;
        costs[Rank.Bronze] = 3 ether / 1000;
        costs[Rank.Silver] = 1 ether / 200;

        admins[msg.sender] = true;
    }

    function totalSupply() public view returns (uint256) {
        return tokenCount;
    }

    function mintToken(
        string memory tokenURI,
        Rank level,
        bool isGraduated
    ) public payable returns (uint256) {
        if (level > Rank.Diamond) {
            revert("Unknown rank");
        }
        if (level == Rank.Diamond) {
            require(admins[msg.sender], "Diamond reserved for admins");
        }
        if (level == Rank.Gold) {
            require(isGraduated, "Gold is only for alumni");
        }
        if (!admins[msg.sender]) {
            require(msg.value > costs[level], "cost requirement not met");
        }
        uint256 newItemId = tokenCount;
        _mint(msg.sender, newItemId);
        users[msg.sender].tokens.push(newItemId);
        if (level > users[msg.sender].rank) {
            users[msg.sender].rank = level;
        }
        _setTokenURI(newItemId, tokenURI);
        tokenCount++;
        payable(owner()).transfer(msg.value);

        return newItemId;
    }

    function getUser(address addr) public view returns (User memory) {
        return users[addr];
    }

    function addAdmin(address addr) public {
        require(admins[msg.sender], "need to be an admin to add admin");
        admins[addr] = true;
    }

    function setCost(Rank rank, uint256 newCost) public {
        require(admins[msg.sender], "need to be an admin to set cost");
        costs[rank] = newCost;
    }
}