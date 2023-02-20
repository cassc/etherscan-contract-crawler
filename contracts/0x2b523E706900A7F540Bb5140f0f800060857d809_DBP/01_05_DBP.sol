// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Designingbypixles
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//     _____     ______     ______      //
//    /\  __-.  /\  == \   /\  == \     //
//    \ \ \/\ \ \ \  __<   \ \  _-/     //
//     \ \____-  \ \_____\  \ \_\       //
//      \/____/   \/_____/   \/_/       //
//                                      //
//                                      //
//                                      //
//////////////////////////////////////////


contract DBP is ERC721Creator {
    constructor() ERC721Creator("Designingbypixles", "DBP") {}
}