// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GOD'S VIEW
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                  //
//                                                                                                                                                                                  //
//    GOD'S VIEW                                                                                                                                                                    //
//                                                                                                                                                                                  //
//    Alaska is one of the most remote regions of the world but also one of the most beautiful places in this blue planet called earth.                                             //
//    Full of forest, glaciars and majestic mountains . It's a harsh and challenging place but at the same time is a place where you can fall in love with such epic landscapes.    //
//    This frames were made while i was flying above Chugach state park in Anchorage during a beautifull sunrise.                                                                   //
//    The light created gave a special colours to this amazing set of mountains and glaciers.                                                                                       //
//                                                                                                                                                                                  //
//                                                                                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GODSVIEW is ERC721Creator {
    constructor() ERC721Creator("GOD'S VIEW", "GODSVIEW") {}
}