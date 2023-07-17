// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bastien × DominikG
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//                                            //
//     /¯¯¯¯/|¯¯¯|  |¯¯¯¯\/¯¯¯¯|              //
//    |       |  ¯¯¯   |                |     //
//    |       | |¯¯¯¯’||     '|\_/|'    ’|    //
//    '\____\|___|¯’|___|    |___|            //
//                                            //
//                                            //
//                                            //
////////////////////////////////////////////////


contract BSDG is ERC721Creator {
    constructor() ERC721Creator(unicode"Bastien × DominikG", "BSDG") {}
}