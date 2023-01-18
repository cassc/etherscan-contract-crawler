// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Real Mineralogy
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////
//                 //
//                 //
//        0        //
//       000       //
//      00000      //
//     0000000     //
//    000000000    //
//     0000000     //
//      00000      //
//       000       //
//        0        //
//                 //
//                 //
/////////////////////


contract MNRL is ERC1155Creator {
    constructor() ERC1155Creator("Real Mineralogy", "MNRL") {}
}