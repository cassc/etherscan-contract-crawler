// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Breadzies
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    BREADZIES NFT    //
//                     //
//                     //
/////////////////////////


contract Breadz is ERC721Creator {
    constructor() ERC721Creator("Breadzies", "Breadz") {}
}