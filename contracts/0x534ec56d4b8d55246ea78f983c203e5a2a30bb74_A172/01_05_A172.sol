// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: A172
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////
//                                                                  //
//                                                                  //
//    ooooo   ooooo ooooo     ooo ooo        ooooo oooooooooooo     //
//    `888'   `888' `888'     `8' `88.       .888' `888'     `8     //
//     888     888   888       8   888b     d'888   888             //
//     888ooooo888   888       8   8 Y88. .P  888   888oooo8        //
//     888     888   888       8   8  `888'   888   888    "        //
//     888     888   `88.    .8'   8    Y     888   888       o     //
//    o888o   o888o    `YbodP'    o8o        o888o o888ooooood8     //
//                                                                  //
//                                                                  //
//                                                                  //
//                                                                  //
//////////////////////////////////////////////////////////////////////


contract A172 is ERC1155Creator {
    constructor() ERC1155Creator("A172", "A172") {}
}