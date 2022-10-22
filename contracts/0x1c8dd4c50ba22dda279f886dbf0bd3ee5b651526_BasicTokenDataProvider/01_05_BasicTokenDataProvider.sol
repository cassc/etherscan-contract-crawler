//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ITokenDataProvider.sol";

contract BasicTokenDataProvider is Ownable, ITokenDataProvider  {

    using Strings for uint256;

    string public baseURI = '';

    constructor(string memory newURI_) Ownable() {
        baseURI = newURI_;
    }

    function setBaseURI(string memory newURI_) public onlyOwner {
        baseURI = newURI_;
    }

    function _baseURI() internal view virtual returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        string memory baseURICopy = _baseURI();
        return bytes(baseURICopy).length > 0 ? string(abi.encodePacked(baseURICopy, tokenId.toString())) : "";
    }
}