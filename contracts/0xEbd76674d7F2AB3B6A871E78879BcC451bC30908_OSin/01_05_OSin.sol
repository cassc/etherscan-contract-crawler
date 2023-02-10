// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ordinal Sins Inscription Pass
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                              //
//                                                                                                              //
//      .oooooo.                  .o8   o8o                        oooo        .oooooo..o  o8o                  //
//     d8P'  `Y8b                "888   `"'                        `888       d8P'    `Y8  `"'                  //
//    888      888 oooo d8b  .oooo888  oooo  ooo. .oo.    .oooo.    888       Y88bo.      oooo  ooo. .oo.       //
//    888      888 `888""8P d88' `888  `888  `888P"Y88b  `P  )88b   888        `"Y8888o.  `888  `888P"Y88b      //
//    888      888  888     888   888   888   888   888   .oP"888   888            `"Y88b  888   888   888      //
//    `88b    d88'  888     888   888   888   888   888  d8(  888   888       oo     .d8P  888   888   888      //
//     `Y8bood8P'  d888b    `Y8bod88P" o888o o888o o888o `Y888""8o o888o      8""88888P'  o888o o888o o888o     //
//                                                                                                              //
//                                                                                                              //
//                                                                                                              //
//                                                                                                              //
//                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract OSin is ERC1155Creator {
    constructor() ERC1155Creator("Ordinal Sins Inscription Pass", "OSin") {}
}