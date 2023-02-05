// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cabin Classics
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//                                                                                        //
//      oooooooo8             oooo       o88                                              //
//    o888     88   ooooooo    888ooooo  oooo  oo oooooo                                  //
//    888           ooooo888   888    888 888   888   888                                 //
//    888o     oo 888    888   888    888 888   888   888                                 //
//     888oooo88   88ooo88 8o o888ooo88  o888o o888o o888o                                //
//                                                                                        //
//      oooooooo8 o888                                   o88                              //
//    o888     88  888   ooooooo    oooooooo8  oooooooo8 oooo   ooooooo    oooooooo8      //
//    888          888   ooooo888  888ooooooo 888ooooooo  888 888     888 888ooooooo      //
//    888o     oo  888 888    888          888        888 888 888                 888     //
//     888oooo88  o888o 88ooo88 8o 88oooooo88 88oooooo88 o888o  88ooo888  88oooooo88      //
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract CBNCLS is ERC1155Creator {
    constructor() ERC1155Creator("Cabin Classics", "CBNCLS") {}
}