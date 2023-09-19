// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Into the shapeless
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//                                                           //
//                                                           //
//    -.-    .       . .          .             .            //
//     | .-.-|-.-.  -|-|-. .-,  .-|-. .-. .-..-,| .-,.-.-    //
//    -'-' ' '-`-'   '-' '-`'-  -'' '-`-`-|-'`'-'-`'--'-'    //
//                                        '                  //
//                                                           //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract intshpls is ERC721Creator {
    constructor() ERC721Creator("Into the shapeless", "intshpls") {}
}