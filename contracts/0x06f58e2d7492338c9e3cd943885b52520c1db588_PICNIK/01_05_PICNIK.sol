// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PicNik
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//                                                       //
//                                                       //
//                                                       //
//                                                       //
//                                                       //
//    *=================PIC O_x NIK=================*    //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract PICNIK is ERC721Creator {
    constructor() ERC721Creator("PicNik", "PICNIK") {}
}