// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: back to square one
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//                                      __      //
//                                     /  |     //
//     ___  __ _ _   _  __ _ _ __ ___  `| |     //
//    / __|/ _` | | | |/ _` | '__/ _ \  | |     //
//    \__ \ (_| | |_| | (_| | | |  __/ _| |_    //
//    |___/\__, |\__,_|\__,_|_|  \___| \___/    //
//            | |                               //
//            |_|                               //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract SQR1 is ERC721Creator {
    constructor() ERC721Creator("back to square one", "SQR1") {}
}