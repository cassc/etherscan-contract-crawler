// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DEGEN SPORTS ART GALLERY
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                             //
//                                                                                                             //
//    d8888b. d88888b  d888b  d88888b d8b   db      .d8888. d8888b.  .d88b.  d8888b. d888888b .d8888.          //
//    88  `8D 88'     88' Y8b 88'     888o  88      88'  YP 88  `8D .8P  Y8. 88  `8D `~~88~~' 88'  YP          //
//    88   88 88ooooo 88      88ooooo 88V8o 88      `8bo.   88oodD' 88    88 88oobY'    88    `8bo.            //
//    88   88 88~~~~~ 88  ooo 88~~~~~ 88 V8o88        `Y8b. 88~~~   88    88 88`8b      88      `Y8b.          //
//    88  .8D 88.     88. ~8~ 88.     88  V888      db   8D 88      `8b  d8' 88 `88.    88    db   8D          //
//    Y8888D' Y88888P  Y888P  Y88888P VP   V8P      `8888Y' 88       `Y88P'  88   YD    YP    `8888Y'          //
//                                                                                                             //
//                                                                                                             //
//          .d8b.  d8888b. d888888b       d888b   .d8b.  db      db      d88888b d8888b. db    db              //
//         d8' `8b 88  `8D `~~88~~'      88' Y8b d8' `8b 88      88      88'     88  `8D `8b  d8'              //
//         88ooo88 88oobY'    88         88      88ooo88 88      88      88ooooo 88oobY'  `8bd8'               //
//         88~~~88 88`8b      88         88  ooo 88~~~88 88      88      88~~~~~ 88`8b      88                 //
//         88   88 88 `88.    88         88. ~8~ 88   88 88booo. 88booo. 88.     88 `88.    88                 //
//         YP   YP 88   YD    YP          Y888P  YP   YP Y88888P Y88888P Y88888P 88   YD    YP                 //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DSAG is ERC721Creator {
    constructor() ERC721Creator("DEGEN SPORTS ART GALLERY", "DSAG") {}
}