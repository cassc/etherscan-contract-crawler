// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: B&O Archives
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//    ########    ####     #######      //
//    ##     ##  ##  ##   ##     ##     //
//    ##     ##   ####    ##     ##     //
//    ########   ####     ##     ##     //
//    ##     ## ##  ## ## ##     ##     //
//    ##     ## ##   ##   ##     ##     //
//    ########   ####  ##  #######      //
//                                      //
//    << Bang & Olufsen Archives >>     //
//                                      //
//                                      //
//////////////////////////////////////////


contract BOAC is ERC721Creator {
    constructor() ERC721Creator("B&O Archives", "BOAC") {}
}