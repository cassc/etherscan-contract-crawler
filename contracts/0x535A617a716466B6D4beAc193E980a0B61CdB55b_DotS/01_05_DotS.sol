// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dreams of the Sea
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                               //
//                                                                                               //
//    .o.                oooo                                           .    ooooooooo           //
//         .888.               `888                                         .o8   d"""""""8'     //
//        .8"888.      .oooo.o  888 .oo.                .oooo.   oooo d8b .o888oo       .8'      //
//       .8' `888.    d88(  "8  888P"Y88b              `P  )88b  `888""8P   888        .8'       //
//      .88ooo8888.   `"Y88b.   888   888               .oP"888   888       888       .8'        //
//     .8'     `888.  o.  )88b  888   888              d8(  888   888       888 .    .8'         //
//    o88o     o8888o 8""888P' o888o o888o ooooooooooo `Y888""8o d888b      "888"   .8'          //
//                                                                                               //
//                                                                                               //
//                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////


contract DotS is ERC721Creator {
    constructor() ERC721Creator("Dreams of the Sea", "DotS") {}
}