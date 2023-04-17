// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LOVELY
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                          //
//                                                                                          //
//                                                                                          //
//    ooooo          .oooooo.   oooooo     oooo oooooooooooo ooooo        oooooo   oooo     //
//    `888'         d8P'  `Y8b   `888.     .8'  `888'     `8 `888'         `888.   .8'      //
//     888         888      888   `888.   .8'    888          888           `888. .8'       //
//     888         888      888    `888. .8'     888oooo8     888            `888.8'        //
//     888         888      888     `888.8'      888    "     888             `888'         //
//     888       o `88b    d88'      `888'       888       o  888       o      888          //
//    o888ooooood8  `Y8bood8P'        `8'       o888ooooood8 o888ooooood8     o888o         //
//                                                                                          //
//                                                                                          //
//                                                                                          //
//                                                                                          //
//                                                                                          //
//                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////


contract LOVELY is ERC1155Creator {
    constructor() ERC1155Creator("LOVELY", "LOVELY") {}
}