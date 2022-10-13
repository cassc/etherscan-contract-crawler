// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kankam ART
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//    Kankam Art and Craft studio    //
//                                   //
//                                   //
///////////////////////////////////////


contract KKM is ERC721Creator {
    constructor() ERC721Creator("Kankam ART", "KKM") {}
}