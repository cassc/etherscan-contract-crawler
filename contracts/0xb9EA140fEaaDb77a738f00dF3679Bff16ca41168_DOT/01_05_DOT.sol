// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: dots
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//          _       _             //
//         | |     | |            //
//       __| | ___ | |_ ___       //
//      / _` |/ _ \| __/ __|      //
//     | (_| | (_) | |_\__ \_     //
//      \__,_|\___/ \__|___(_)    //
//                                //
//                                //
//                                //
//                                //
////////////////////////////////////


contract DOT is ERC721Creator {
    constructor() ERC721Creator("dots", "DOT") {}
}