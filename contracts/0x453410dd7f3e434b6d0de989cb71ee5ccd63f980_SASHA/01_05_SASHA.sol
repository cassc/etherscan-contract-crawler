// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sasha Kim
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                       //
//                                                                                                                       //
//     .oooooo..o       .o.        .oooooo..o ooooo   ooooo       .o.            oooo    oooo ooooo ooo        ooooo     //
//    d8P'    `Y8      .888.      d8P'    `Y8 `888'   `888'      .888.           `888   .8P'  `888' `88.       .888'     //
//    Y88bo.          .8"888.     Y88bo.       888     888      .8"888.           888  d8'     888   888b     d'888      //
//     `"Y8888o.     .8' `888.     `"Y8888o.   888ooooo888     .8' `888.          88888[       888   8 Y88. .P  888      //
//         `"Y88b   .88ooo8888.        `"Y88b  888     888    .88ooo8888.         888`88b.     888   8  `888'   888      //
//    oo     .d8P  .8'     `888.  oo     .d8P  888     888   .8'     `888.        888  `88b.   888   8    Y     888      //
//    8""88888P'  o88o     o8888o 8""88888P'  o888o   o888o o88o     o8888o      o888o  o888o o888o o8o        o888o     //
//                                                                                                                       //
//                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SASHA is ERC721Creator {
    constructor() ERC721Creator("Sasha Kim", "SASHA") {}
}