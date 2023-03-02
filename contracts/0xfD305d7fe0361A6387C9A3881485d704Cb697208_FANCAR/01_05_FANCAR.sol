// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fancy Cars
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////
//                                                                  //
//                                                                  //
//    =====-------------------------------  ---- == -======== **    //
//                                                                  //
//      o888o                                                       //
//    o888oo ooooooo   oo oooooo    ooooooo  oooo   oooo            //
//     888   ooooo888   888   888 888     888 888   888             //
//     888 888    888   888   888 888          888 888              //
//    o888o 88ooo88 8o o888o o888o  88ooo888     8888               //
//                                            o8o888                //
//                                                                  //
//      ooooooo   ooooooo   oo oooooo    oooooooo8                  //
//    888     888 ooooo888   888    888 888ooooooo                  //
//    888       888    888   888                888                 //
//      88ooo888 88ooo88 8o o888o       88oooooo88                  //
//                                                                  //
//                by                                                //
//          .-.          _                                          //
//          : :         :_;                                         //
//     .--. : `-. .-.,-..-..-..-.,-.,-.,-.                          //
//    ' .; :' .; :`.  .': :: :; :: ,. ,. :                          //
//    `.__.'`.__.':_,._;:_;`.__.':_;:_;:_;                          //
//                                                                  //
//      *=---                                                       //
//                                                                  //
//    How can one be expected to HODL when there are fancy cars?    //
//                                                                  //
//    =====-------------------------------  ---- == -======== **    //
//                                                                  //
//                                                                  //
//                                                                  //
//////////////////////////////////////////////////////////////////////


contract FANCAR is ERC721Creator {
    constructor() ERC721Creator("Fancy Cars", "FANCAR") {}
}