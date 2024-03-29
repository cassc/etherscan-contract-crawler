// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Greystache MT OG KEY
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                          //
//                                                                                                          //
//                                                                                                          //
//     _______    ______   ___ __ __   _________   ______   _______      ___   ___   ______   __  __        //
//    /______/\  /_____/\ /__//_//_/\ /________/\ /_____/\ /______/\    /___/\/__/\ /_____/\ /_/\/_/\       //
//    \::::__\/__\::::_\/_\::\| \| \ \\__.::.__\/ \:::_ \ \\::::__\/__  \::.\ \\ \ \\::::_\/_\ \ \ \ \      //
//     \:\ /____/\\:\/___/\\:.      \ \  \::\ \    \:\ \ \ \\:\ /____/\  \:: \/_) \ \\:\/___/\\:\_\ \ \     //
//      \:\\_  _\/ \_::._\:\\:.\-/\  \ \  \::\ \    \:\ \ \ \\:\\_  _\/   \:. __  ( ( \::___\/_\::::_\/     //
//       \:\_\ \ \   /____\:\\. \  \  \ \  \::\ \    \:\_\ \ \\:\_\ \ \    \: \ )  \ \ \:\____/\ \::\ \     //
//        \_____\/   \_____\/ \__\/ \__\/   \__\/     \_____\/ \_____\/     \__\/\__\/  \_____\/  \__\/     //
//                                                                                                          //
//                                                                                                          //
//                                                                                                          //
//                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GSMTOG is ERC721Creator {
    constructor() ERC721Creator("Greystache MT OG KEY", "GSMTOG") {}
}