// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../../utils/Origin.sol";
import "./values.sol";

abstract contract Puppet is Origin, Honor {
    string private _baseURI = "";

    function tokenURI(uint tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Unknown token");
        return string(abi.encodePacked(_baseURI, Strings.toString(tokenId)));
    }

    function setBaseURI(string memory uri) external onlyOrigin {
        _baseURI = uri;
    }

    constructor(
        string memory name,
        string memory symbol,
        address origin,
        string memory baseURI
    ) Origin(origin) Honor(name, symbol) {
        _baseURI = baseURI;
    }
}