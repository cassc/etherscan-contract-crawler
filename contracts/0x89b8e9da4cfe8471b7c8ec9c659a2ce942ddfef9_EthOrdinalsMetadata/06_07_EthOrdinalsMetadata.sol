// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Ownable} from "@openzeppelin-contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin-contracts/utils/Strings.sol";
import {IEthOrdinalsMetadata} from "./interfaces/IEthOrdinalsMetadata.sol";

contract EthOrdinalsMetadata is IEthOrdinalsMetadata, Ownable {
    string public baseURI;

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
            string(
                abi.encodePacked(baseURI, Strings.toString(tokenId), ".json")
            );
    }

    function setBaseUri(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }
}