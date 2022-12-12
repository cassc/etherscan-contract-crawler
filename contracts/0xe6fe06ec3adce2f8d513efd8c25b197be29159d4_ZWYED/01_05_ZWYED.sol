// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ZwyBel (Artist) Multi-editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                    //
//                                                                                                    //
//     oooooooooooo oooooo   oooooo     oooo oooooo   oooo oooooooooo.  oooooooooooo ooooo            //
//    d'""""""d888'  `888.    `888.     .8'   `888.   .8'  `888'   `Y8b `888'     `8 `888'            //
//          .888P     `888.   .8888.   .8'     `888. .8'    888     888  888          888             //
//         d888'       `888  .8'`888. .8'       `888.8'     888oooo888'  888oooo8     888             //
//       .888P          `888.8'  `888.8'         `888'      888    `88b  888    "     888             //
//      d888'    .P      `888'    `888'           888       888    .88P  888       o  888       o     //
//    .8888888888P        `8'      `8'           o888o     o888bood8P'  o888ooooood8 o888ooooood8     //
//                                                                                                    //
//                                                                                                    //
//                                                                                                    //
//                                                                                                    //
//                                                                                                    //
//                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ZWYED is ERC1155Creator {
    constructor() ERC1155Creator("ZwyBel (Artist) Multi-editions", "ZWYED") {}
}