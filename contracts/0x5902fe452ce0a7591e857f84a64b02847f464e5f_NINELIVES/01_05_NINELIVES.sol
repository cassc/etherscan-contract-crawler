// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nine Lives
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                          //
//                                                                                                                          //
//                                                                                                                          //
//                                                                                                                          //
//                                                                                                                          //
//                                                                                                                          //
//    ooooo      ooo ooooo ooooo      ooo oooooooooooo      ooooo        ooooo oooooo     oooo oooooooooooo  .oooooo..o     //
//    `888b.     `8' `888' `888b.     `8' `888'     `8      `888'        `888'  `888.     .8'  `888'     `8 d8P'    `Y8     //
//     8 `88b.    8   888   8 `88b.    8   888               888          888    `888.   .8'    888         Y88bo.          //
//     8   `88b.  8   888   8   `88b.  8   888oooo8          888          888     `888. .8'     888oooo8     `"Y8888o.      //
//     8     `88b.8   888   8     `88b.8   888    "          888          888      `888.8'      888    "         `"Y88b     //
//     8       `888   888   8       `888   888       o       888       o  888       `888'       888       o oo     .d8P     //
//    o8o        `8  o888o o8o        `8  o888ooooood8      o888ooooood8 o888o       `8'       o888ooooood8 8""88888P'      //
//                                                                                                                          //
//                                                                                                                          //
//                                                                                                                          //
//                                                                                                                          //
//                                                                                                                          //
//                                                                                                                          //
//                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract NINELIVES is ERC721Creator {
    constructor() ERC721Creator("Nine Lives", "NINELIVES") {}
}