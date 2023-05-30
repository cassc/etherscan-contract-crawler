// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: valcour
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////
//                                                                             //
//                                                                             //
//                          oooo                                               //
//                          `888                                               //
//    oooo    ooo  .oooo.    888   .ooooo.   .ooooo.  oooo  oooo  oooo d8b     //
//     `88.  .8'  `P  )88b   888  d88' `"Y8 d88' `88b `888  `888  `888""8P     //
//      `88..8'    .oP"888   888  888       888   888  888   888   888         //
//       `888'    d8(  888   888  888   .o8 888   888  888   888   888         //
//        `8'     `Y888""8o o888o `Y8bod8P' `Y8bod8P'  `V88V"V8P' d888b        //
//                                                                             //
//                                                                             //
/////////////////////////////////////////////////////////////////////////////////


contract V1 is ERC721Creator {
    constructor() ERC721Creator("valcour", "V1") {}
}