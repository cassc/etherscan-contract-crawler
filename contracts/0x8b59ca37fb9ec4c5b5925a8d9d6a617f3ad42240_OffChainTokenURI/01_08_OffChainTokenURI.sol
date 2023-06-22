// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ITokenURI.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract OffChainTokenURI is Ownable2Step, ITokenURI {
    using Strings for uint256;

    string public baseURI;

    constructor(string memory baseURI_)
    {
        baseURI = baseURI_;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory uri_) {
        return string(abi.encodePacked(baseURI, tokenId.toString()));        
    }
}