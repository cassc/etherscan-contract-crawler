// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: byval42
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////
//                                                                                       //
//                                                                                       //
//                                                                                       //
//    /***                                                                               //
//     *     .o8                                         oooo        .o     .oooo.       //
//     *    "888                                         `888      .d88   .dP""Y88b      //
//     *     888oooo.  oooo    ooo oooo    ooo  .oooo.    888    .d'888         ]8P'     //
//     *     d88' `88b  `88.  .8'   `88.  .8'  `P  )88b   888  .d'  888       .d8P'      //
//     *     888   888   `88..8'     `88..8'    .oP"888   888  88ooo888oo   .dP'         //
//     *     888   888    `888'       `888'    d8(  888   888       888   .oP     .o     //
//     *     `Y8bod8P'     .8'         `8'     `Y888""8o o888o     o888o  8888888888     //
//     *               .o..P'                                                            //
//     *               `Y8P'                                                             //
//     *                                                                                 //
//     */                                                                                //
//                                                                                       //
//                                                                                       //
//                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////


contract byval42 is ERC1155Creator {
    constructor() ERC1155Creator("byval42", "byval42") {}
}