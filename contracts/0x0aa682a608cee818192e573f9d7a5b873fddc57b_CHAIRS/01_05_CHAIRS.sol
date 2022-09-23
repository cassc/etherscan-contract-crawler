// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Chairs
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    Chairs by Gleidstan    //
//    --------------2022-    //
//                           //
//          `------`         //
//           ------          //
//           -    -          //
//           \\\\\\\         //
//          | \\\\\\\        //
//          | |   | |        //
//            |     |        //
//                           //
//                           //
///////////////////////////////


contract CHAIRS is ERC721Creator {
    constructor() ERC721Creator("Chairs", "CHAIRS") {}
}