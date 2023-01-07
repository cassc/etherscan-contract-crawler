// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Art?
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//                                             //
//                                             //
//        // | |                     __        //
//       //__| |     __    __  ___ ((  ) )     //
//      / ___  |   //  ) )  / /       / /      //
//     //    | |  //       / /       ( /       //
//    //     | | //       / /        ()        //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract BANK is ERC721Creator {
    constructor() ERC721Creator("Art?", "BANK") {}
}