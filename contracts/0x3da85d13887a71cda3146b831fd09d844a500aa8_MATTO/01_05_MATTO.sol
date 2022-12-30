// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Matto Runs
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

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
//             ooooooooo.   ooooo     ooo ooooo      ooo  .oooooo..o                //
//             `888   `Y88. `888'     `8' `888b.     `8' d8P'    `Y8                //
//              888   .d88'  888       8   8 `88b.    8  Y88bo.                     //
//              888ooo88P'   888       8   8   `88b.  8   `"Y8888o.                 //
//              888`88b.     888       8   8     `88b.8       `"Y88b                //
//              888  `88b.   `88.    .8'   8       `888  oo     .d8P                //
//             o888o  o888o    `YbodP'    o8o        `8  8""88888P'                 //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////


contract MATTO is ERC1155Creator {
    constructor() ERC1155Creator("Matto Runs", "MATTO") {}
}