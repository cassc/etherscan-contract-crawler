// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

contract NFT is ERC721A, Ownable
{
    constructor(uint256[] memory _tokenIds, address tokensOwner) ERC721A("Moonblrds", "MBS")
    {
        _mint(tokensOwner, _tokenIds.length);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked("ipfs://Qmboe8Co16m2DV6ppeuUpNArx6QJpXh3fk7esa8yFnK2HC/", Strings.toString(_tokenId), ".json"));
    }
}