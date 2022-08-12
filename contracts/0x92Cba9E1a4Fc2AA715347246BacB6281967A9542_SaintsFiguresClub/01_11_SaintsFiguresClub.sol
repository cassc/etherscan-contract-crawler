// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC721X.sol";

contract SaintsFiguresClub is ERC721 {
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        address defaultOwner_,
        string memory baseUrl_
    ) ERC721(name_, symbol_, totalSupply_, defaultOwner_, baseUrl_) {
        metadataFileExt = ".json";
    }
}