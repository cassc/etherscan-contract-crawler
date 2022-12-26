// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Merry Xmas Sweets
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//                                        //
//     ____  ___                          //
//     \   \/  / _____ _____    ______    //
//      \     / /     \\__  \  /  ___/    //
//      /     \|  Y Y  \/ __ \_\___ \     //
//     /___/\  \__|_|  (____  /____  >    //
//           \_/     \/     \/     \/     //
//                                        //
//                                        //
//                                        //
////////////////////////////////////////////


contract XMAS is ERC721Creator {
    constructor() ERC721Creator("Merry Xmas Sweets", "XMAS") {}
}