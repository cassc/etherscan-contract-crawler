// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Korekuta
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////
//                //
//                //
//    KOREKUTA    //
//                //
//                //
////////////////////


contract VolumeOne is ERC721Creator {
    constructor() ERC721Creator("Korekuta", "VolumeOne") {}
}