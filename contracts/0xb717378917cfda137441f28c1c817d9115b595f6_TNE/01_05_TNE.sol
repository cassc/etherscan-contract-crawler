// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: THE NEW ERA
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//                                    //
//      _____   _   _   U _____ u     //
//     |_ " _| | \ |"|  \| ___"|/     //
//       | |  <|  \| |>  |  _|"       //
//      /| |\ U| |\  |u  | |___       //
//     u |_|U  |_| \_|   |_____|      //
//     _// \\_ ||   \\,-.<<   >>      //
//    (__) (__)(_")  (_/(__) (__)     //
//                                    //
//                                    //
//                                    //
////////////////////////////////////////


contract TNE is ERC721Creator {
    constructor() ERC721Creator("THE NEW ERA", "TNE") {}
}