// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Be Mine
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                          //
//                                                                                          //
//    oooooooooo.  oooooooooooo      ooo        ooooo ooooo ooooo      ooo oooooooooooo     //
//    `888'   `Y8b `888'     `8      `88.       .888' `888' `888b.     `8' `888'     `8     //
//     888     888  888               888b     d'888   888   8 `88b.    8   888             //
//     888oooo888'  888oooo8          8 Y88. .P  888   888   8   `88b.  8   888oooo8        //
//     888    `88b  888    "          8  `888'   888   888   8     `88b.8   888    "        //
//     888    .88P  888       o       8    Y     888   888   8       `888   888       o     //
//    o888bood8P'  o888ooooood8      o8o        o888o o888o o8o        `8  o888ooooood8     //
//                                                                                          //
//                                                                                          //
//                                                                                          //
//                                                                                          //
//                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////


contract lessthan3 is ERC1155Creator {
    constructor() ERC1155Creator("Be Mine", "lessthan3") {}
}