// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 1155 CRIME
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////
//                                                                      //
//                                                                      //
//                                                                      //
//      .oooooo.   ooooooooo.   ooooo ooo        ooooo oooooooooooo     //
//     d8P'  `Y8b  `888   `Y88. `888' `88.       .888' `888'     `8     //
//    888           888   .d88'  888   888b     d'888   888             //
//    888           888ooo88P'   888   8 Y88. .P  888   888oooo8        //
//    888           888`88b.     888   8  `888'   888   888    "        //
//    `88b    ooo   888  `88b.   888   8    Y     888   888       o     //
//     `Y8bood8P'  o888o  o888o o888o o8o        o888o o888ooooood8     //
//                                                  CRIME BREAKFAST     //
//                                                                      //
//                                                                      //
//////////////////////////////////////////////////////////////////////////


contract CRIME is ERC1155Creator {
    constructor() ERC1155Creator("1155 CRIME", "CRIME") {}
}