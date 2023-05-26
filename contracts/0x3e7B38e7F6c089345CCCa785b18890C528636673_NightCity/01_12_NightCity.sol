//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NightCity is ERC721A, Ownable {
    string  public baseURI;

    constructor(string memory uri) ERC721A ("Night City", "NCTY") {
        setBaseURI(uri);
    }

    function mint(address[] calldata dest, uint256[] calldata quantity) public onlyOwner {
        for(uint256 i = 0; i < dest.length; i++) {
            _safeMint(dest[i], quantity[i]);
        }
    }

    function _startTokenId() internal view virtual override(ERC721A) returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override(ERC721A) returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }


}