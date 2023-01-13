// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sketches by Mad Monk
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                             //
//                                                                                             //
//    .d8888. db   dD d88888b d888888b  .o88b. db   db d88888b .d8888.                         //
//    88'  YP 88 ,8P' 88'     `~~88~~' d8P  Y8 88   88 88'     88'  YP                         //
//    `8bo.   88,8P   88ooooo    88    8P      88ooo88 88ooooo `8bo.                           //
//      `Y8b. 88`8b   88~~~~~    88    8b      88~~~88 88~~~~~   `Y8b.                         //
//    db   8D 88 `88. 88.        88    Y8b  d8 88   88 88.     db   8D                         //
//    `8888Y' YP   YD Y88888P    YP     `Y88P' YP   YP Y88888P `8888Y'                         //
//                                                                                             //
//                                                                                             //
//    d8888b. db    db   .88b  d88.  .d8b.  d8888b.   .88b  d88.  .d88b.  d8b   db db   dD     //
//    88  `8D `8b  d8'   88'YbdP`88 d8' `8b 88  `8D   88'YbdP`88 .8P  Y8. 888o  88 88 ,8P'     //
//    88oooY'  `8bd8'    88  88  88 88ooo88 88   88   88  88  88 88    88 88V8o 88 88,8P       //
//    88~~~b.    88      88  88  88 88~~~88 88   88   88  88  88 88    88 88 V8o88 88`8b       //
//    88   8D    88      88  88  88 88   88 88  .8D   88  88  88 `8b  d8' 88  V888 88 `88.     //
//    Y8888P'    YP      YP  YP  YP YP   YP Y8888D'   YP  YP  YP  `Y88P'  VP   V8P YP   YD     //
//                                                                                             //
//                                                                                             //
//                                                                                             //
//                                                                                             //
//                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////


contract SKMAD is ERC721Creator {
    constructor() ERC721Creator("Sketches by Mad Monk", "SKMAD") {}
}