// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: David's Polygon
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//    Polygon by David    //
//                        //
//                        //
////////////////////////////


contract DM is ERC721Creator {
    constructor() ERC721Creator("David's Polygon", "DM") {}
}