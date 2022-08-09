// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/// @title 8liensThirdEye
/// @author 8liens (https://twitter.com/8liensNFT)
/// @author Developer: dievardump (https://twitter.com/dievardump, [email protected])
contract $8liensThirdEye is Ownable {
    string public baseURI;

    string public defaultURI =
        "ipfs://QmWQouxrn2uisPD6ucR18hVBWAmvy1gmins4JApYm3YJ6a";

    string public constant name = "8liens Third Eye";

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        if (bytes(baseURI).length > 0) {
            return string.concat(baseURI, Strings.toString(tokenId), ".json");
        }

        return defaultURI;
    }

    /////////////////////////////////////////////////////////
    // Gated Owner                                         //
    /////////////////////////////////////////////////////////

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function setDefaultURI(string calldata newDefaultURI) external onlyOwner {
        defaultURI = newDefaultURI;
    }
}