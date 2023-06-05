// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {ERC2981} from "../../ERC2981/ERC2981.sol";
import {ERC721} from "../ERC721.sol";

abstract contract ERC721Royalty is ERC721, ERC2981 {

    constructor(address receiver, uint256 fee) ERC2981(receiver, fee) {}


    function setDefaultRoyaltyInfo(address receiver, uint256 fee) internal onlyOwner {
        _setDefaultRoyaltyInfo(receiver, fee);
    }

    function setRoyaltyInfo(uint256 tokenId, address receiver, uint256 fee) internal onlyOwner {
        _setRoyaltyInfo(tokenId, receiver, fee);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}