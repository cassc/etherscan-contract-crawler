//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./core/NPass.sol";

contract MutantVerseDNA is NPass {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 public publicPrice = 0.08 ether;
    bool public publicSale = false;

    string public baseTokenURI = "POSTMINTUPDATE";

    constructor()
        NPass(
            0x05a46f1E545526FB803FF974C790aCeA34D1f2D6,
            "MutantVerseDNA",
            "dNa",
            true,
            8888,
            0,
            50000000000000000,
            80000000000000000
        )
    {}

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    // Override so the openzeppelin tokenURI() method will use this method to create the full tokenURI instead
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
    function to update tokenURL
   */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    function setPublicSale(bool _publicSale) public onlyOwner {
        publicSale = _publicSale;
    }

    /**
    Minting function
    */

    function mint(uint256 _tokenId) public payable {
        require(_tokenId > 0 && _tokenId <= 8888, "Token ID invalid");
        require(msg.value == publicPrice, "Incorrect price");
        require(publicSale, "Public sale is not active");
        _safeMint(msg.sender, _tokenId);
    }
}