// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Avlevytska
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//        |     '||''|.   |''||''|     //
//       |||     ||   ||     ||        //
//      |  ||    ||''|'      ||        //
//     .''''|.   ||   |.     ||        //
//    .|.  .||. .||.  '|'   .||.       //
//                                     //
//                                     //
//                                     //
//                                     //
/////////////////////////////////////////


contract AVLE is ERC721Creator {
    constructor() ERC721Creator("Avlevytska", "AVLE") {}
}