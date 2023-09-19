// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: silent monks
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//                                               //
//     _   _ _    ____ _  _ ___                  //
//    [__  | |    |___ |\ |  |                   //
//    ___] | |___ |___ | \|  |                   //
//                                               //
//     _   _  _ ____ ___ ____ _  _ ____  _       //
//    [__  |_/  |___  |  |    |__| |___ [__      //
//    ___] | \_ |___  |  |___ |  | |___ ___]     //
//                                               //
//                                               //
//    by pale kirill                             //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract MNKS is ERC721Creator {
    constructor() ERC721Creator("silent monks", "MNKS") {}
}