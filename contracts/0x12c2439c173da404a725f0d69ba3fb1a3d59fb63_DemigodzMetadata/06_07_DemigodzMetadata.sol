// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Ownable} from "@openzeppelin-contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin-contracts/utils/Strings.sol";
import {IDemigodzMetadata} from "./interfaces/IDemigodzMetadata.sol";

contract DemigodzMetadata is IDemigodzMetadata, Ownable {
    string public baseURI;

    bool public revealed;

    constructor(string memory baseURI_) {
        baseURI = baseURI_;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        returns (string memory)
    {
        if (bytes(baseURI).length == 0) {
            return "";
        }
        return
            revealed
                ? string(abi.encodePacked(baseURI, Strings.toString(tokenId)))
                : baseURI;
    }

    function toggleReveal() public onlyOwner {
        revealed = !revealed;
    }

    function setBaseUri(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }
}