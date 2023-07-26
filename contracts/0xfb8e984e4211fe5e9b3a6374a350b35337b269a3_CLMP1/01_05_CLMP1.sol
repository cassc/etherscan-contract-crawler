// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Calma NFT - PHASE 01 -  Exit Reality
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                               //
//                                                                                                               //
//      .oooooo.             oooo                                  ooooo      ooo oooooooooooo ooooooooooooo     //
//     d8P'  `Y8b            `888                                  `888b.     `8' `888'     `8 8'   888   `8     //
//    888           .oooo.    888  ooo. .oo.  .oo.    .oooo.        8 `88b.    8   888              888          //
//    888          `P  )88b   888  `888P"Y88bP"Y88b  `P  )88b       8   `88b.  8   888oooo8         888          //
//    888           .oP"888   888   888   888   888   .oP"888       8     `88b.8   888    "         888          //
//    `88b    ooo  d8(  888   888   888   888   888  d8(  888       8       `888   888              888          //
//     `Y8bood8P'  `Y888""8o o888o o888o o888o o888o `Y888""8o     o8o        `8  o888o            o888o         //
//                                                                                                               //
//                                                                                                               //
//                                                                                                               //
//                                                                                                               //
//                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CLMP1 is ERC1155Creator {
    constructor() ERC1155Creator("Calma NFT - PHASE 01 -  Exit Reality", "CLMP1") {}
}