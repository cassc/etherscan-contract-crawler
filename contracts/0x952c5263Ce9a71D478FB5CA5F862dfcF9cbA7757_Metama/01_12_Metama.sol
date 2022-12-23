// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { ERC721, IERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Metama is ERC721, Ownable{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string private tokenURI_;

    constructor(
        string memory _tokenURI
    )ERC721("METAMA", "MTM"){
        tokenURI_ = _tokenURI;
    }

    function mint() public onlyOwner{
        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();
        _mint(msg.sender, tokenId);
    }

    function tokenURI(uint256 _tokenId) public view virtual override(ERC721) returns (string memory){
        return tokenURI_;
    }

    function totalSupply() public view returns (uint256){
        return _tokenIds.current();
    }

    function setTokenURI(string memory _tokenURI) public{
        tokenURI_ = _tokenURI;
    }
}