// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Nouners - Pilot Episode Access
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                //
//                                                                                                                //
//     .o8                   ooooooooo.   oooooooooooo oooo    oooo   .oooooo.   ooooo              .o.           //
//    "888                   `888   `Y88. `888'     `8 `888   .8P'   d8P'  `Y8b  `888'             .888.          //
//     888oooo.  oooo    ooo  888   .d88'  888          888  d8'    888      888  888             .8"888.         //
//     d88' `88b  `88.  .8'   888ooo88P'   888oooo8     88888[      888      888  888            .8' `888.        //
//     888   888   `88..8'    888`88b.     888    "     888`88b.    888      888  888           .88ooo8888.       //
//     888   888    `888'     888  `88b.   888       o  888  `88b.  `88b    d88'  888       o  .8'     `888.      //
//     `Y8bod8P'      8'     o888o  o888o o888ooooood8 o888o  o888o  `Y8bood8P'  o888ooooood8 o88o     o8888o     //
//                  .8                                                                                            //
//                                                                                                                //
//                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract THENOUNERS is ERC721Creator {
    constructor() ERC721Creator("The Nouners - Pilot Episode Access", "THENOUNERS") {}
}