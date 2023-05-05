// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IRenderer} from "./IRenderer.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";


contract StaticSiteRenderer is IRenderer {
    function tokenURI(uint256 tokenId) external pure override returns (string memory) {
        return string.concat("https://www.draup.xyz/api/collection_00/", Strings.toString(tokenId));
    }
}