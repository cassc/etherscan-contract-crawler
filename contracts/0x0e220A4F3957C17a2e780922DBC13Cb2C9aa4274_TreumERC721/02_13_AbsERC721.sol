// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

abstract contract AbsERC721 is ERC721 {
    string public baseURI;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURIParam
    ) ERC721(name, symbol) {
        _setBaseURI(baseURIParam);
    }

    function setBaseURI(string memory baseURIParam) external virtual;

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(super.tokenURI(tokenId), ".json"));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _setBaseURI(string memory baseURIParam) internal {
        baseURI = baseURIParam;
    }
}