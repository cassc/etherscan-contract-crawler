// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Ownable} from "openzeppelin/access/Ownable.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";

import "../IMetadataRenderer.sol";

contract JSONURIRenderer is IMetadataRenderer, Ownable {
    string public baseURI;

    constructor(string memory _baseURI) {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return string.concat(baseURI, Strings.toString(id), ".json");
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }
}