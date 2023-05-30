// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LELEXVENERE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//    ooooo        oooooooooooo ooooo        oooooooooooo      ooooooo  ooooo      oooooo     oooo oooooooooooo ooooo      ooo oooooooooooo ooooooooo.   oooooooooooo     //
//    `888'        `888'     `8 `888'        `888'     `8       `8888    d8'        `888.     .8'  `888'     `8 `888b.     `8' `888'     `8 `888   `Y88. `888'     `8     //
//     888          888          888          888                 Y888..8P           `888.   .8'    888          8 `88b.    8   888          888   .d88'  888             //
//     888          888oooo8     888          888oooo8             `8888'             `888. .8'     888oooo8     8   `88b.  8   888oooo8     888ooo88P'   888oooo8        //
//     888          888    "     888          888    "            .8PY888.             `888.8'      888    "     8     `88b.8   888    "     888`88b.     888    "        //
//     888       o  888       o  888       o  888       o        d8'  `888b             `888'       888       o  8       `888   888       o  888  `88b.   888       o     //
//    o888ooooood8 o888ooooood8 o888ooooood8 o888ooooood8      o888o  o88888o            `8'       o888ooooood8 o8o        `8  o888ooooood8 o888o  o888o o888ooooood8     //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LXV is ERC1155Creator {
    constructor() ERC1155Creator("LELEXVENERE", "LXV") {}
}