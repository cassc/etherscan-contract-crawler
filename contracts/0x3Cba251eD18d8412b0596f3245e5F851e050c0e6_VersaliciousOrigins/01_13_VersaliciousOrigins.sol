//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract VersaliciousOrigins is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    uint totalSupply;
    constructor() ERC721("Versalicious Origins", "VERL0") {
         totalSupply = 0;
    }

// This method mints new NFTs, and makes sure that supply is limited to 19 tokens
    function mintNFT(address recipient, string memory tokenURI)
        public onlyOwner
        returns (string memory)
    
    {   if ( totalSupply <= 18 ) {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI);
        totalSupply = totalSupply + 1;
        string memory tokenID = Strings.toString(newItemId);
        string memory tokenMintedSuccess = string.concat("Token with the following ID minted Successfully: ", tokenID);
        return tokenMintedSuccess;
    }
    else {
        revert( "Max supply of 18 VersaliciousOrigins + 1 Dungeon Keeper reached ");
    }

    }

    function setTokenURI(uint256 tokenID, string memory tokenURI)
        public onlyOwner
        returns (string memory)
    {
        _setTokenURI(tokenID, tokenURI);
        string memory tokenChange = "Token URI Changed";
        return tokenChange;
    }  


}