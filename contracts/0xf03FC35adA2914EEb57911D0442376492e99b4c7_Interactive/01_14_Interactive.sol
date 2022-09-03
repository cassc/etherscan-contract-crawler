//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import {Base64} from "base64-sol/base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract Interactive is ERC721Enumerable, Ownable {
    constructor() ERC721("InJungle", "JNGL") {}

    mapping(uint256 => uint256) public price;

    uint256 public nextTokenId = 0;
    uint256 public tokenLimit = 36;

    function setPrice(uint256 tokenId, uint256 newPrice) public {
        require(_exists(tokenId), "nonexistent token");
        require(ownerOf(tokenId) == msg.sender, "not an owner");
        price[tokenId] = newPrice;
    }

    function buy(uint256 tokenId) public payable {
        require(_exists(tokenId), "nonexistent token");
        require(ownerOf(tokenId) != msg.sender, "owner");
        require(price[tokenId] > 0, "token price not set");
        require(price[tokenId] == msg.value, "invalid token value");

        address nftOwner = ownerOf(tokenId);
        (bool sent, ) = nftOwner.call{value: msg.value}("");
        require(sent, "failed to send");
        _transfer(nftOwner, msg.sender, tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "nonexistent token");

        string memory tokenIdString = Strings.toString(tokenId);
        string
            memory nftImage = "ipfs://QmPL5cAtAWokUQQB5T9FXkssZsNtLNtvtXkNUbZrY9aowq/";
        string memory json = Base64.encode(
            abi.encodePacked(
                '{"name":"in jungle #',
                tokenIdString,
                '", "animation_url":"https://injungle.xyz/',
                tokenIdString,
                '", "external_url":"https://injungle.xyz/',
                tokenIdString,
                '", "image": "',
                nftImage,
                tokenIdString,
                '"}'
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function mint() public {
        require(nextTokenId < tokenLimit);
        _safeMint(msg.sender, nextTokenId);
        nextTokenId += 1;
    }
}