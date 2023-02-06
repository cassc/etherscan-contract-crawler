// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tomajo Gakuen Pass
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//                                           //
//      _______ _____ _____                  //
//     |__   __/ ____|  __ \                 //
//        | | | |  __| |__) |_ _ ___ ___     //
//        | | | | |_ |  ___/ _` / __/ __|    //
//        | | | |__| | |  | (_| \__ \__ \    //
//        |_|  \_____|_|   \__,_|___/___/    //
//                                           //
//                                           //
//                                           //
//                                           //
//                                           //
//                                           //
///////////////////////////////////////////////


contract TGP is ERC1155Creator {
    constructor() ERC1155Creator("Tomajo Gakuen Pass", "TGP") {}
}