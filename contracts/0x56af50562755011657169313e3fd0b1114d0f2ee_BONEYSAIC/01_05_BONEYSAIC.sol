// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Boneysaic
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    Boneysaic    //
//                 //
//                 //
/////////////////////


contract BONEYSAIC is ERC721Creator {
    constructor() ERC721Creator("Boneysaic", "BONEYSAIC") {}
}