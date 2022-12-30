// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Matto Ones
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////
//                                                                                  //
//                                                                                  //
//    ooo        ooooo       .o.       ooooooooooooo ooooooooooooo   .oooooo.       //
//    `88.       .888'      .888.      8'   888   `8 8'   888   `8  d8P'  `Y8b      //
//     888b     d'888      .8"888.          888           888      888      888     //
//     8 Y88. .P  888     .8' `888.         888           888      888      888     //
//     8  `888'   888    .88ooo8888.        888           888      888      888     //
//     8    Y     888   .8'     `888.       888           888      `88b    d88'     //
//    o8o        o888o o88o     o8888o     o888o         o888o      `Y8bood8P'      //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//               .oooooo.   ooooo      ooo oooooooooooo  .oooooo..o                 //
//              d8P'  `Y8b  `888b.     `8' `888'     `8 d8P'    `Y8                 //
//             888      888  8 `88b.    8   888         Y88bo.                      //
//             888      888  8   `88b.  8   888oooo8     `"Y8888o.                  //
//             888      888  8     `88b.8   888    "         `"Y88b                 //
//             `88b    d88'  8       `888   888       o oo     .d8P                 //
//              `Y8bood8P'  o8o        `8  o888ooooood8 8""88888P'                  //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////


contract MATTO is ERC721Creator {
    constructor() ERC721Creator("Matto Ones", "MATTO") {}
}