// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Animal Music Scroll
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//        _        __  __     ____         //
//    U  /"\  u  U|' \/ '|u  / __"| u      //
//     \/ _ \/   \| |\/| |/ <\___ \/       //
//     / ___ \    | |  | |   u___) |       //
//    /_/   \_\   |_|  |_|   |____/>>      //
//     \\    >>  <<,-,,-.     )(  (__)     //
//    (__)  (__)  (./  \.)   (__)          //
//                                         //
//                                         //
/////////////////////////////////////////////


contract AMS is ERC721Creator {
    constructor() ERC721Creator("Animal Music Scroll", "AMS") {}
}