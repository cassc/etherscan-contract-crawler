// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Carlo Van de Roer - Modulator One
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//                                             //
//     ____     __  __  ____    ____           //
//    /\  _`\  /\ \/\ \/\  _`\ /\  _`\         //
//    \ \ \/\_\\ \ \ \ \ \ \/\ \ \ \L\ \       //
//     \ \ \/_/_\ \ \ \ \ \ \ \ \ \ ,  /       //
//      \ \ \L\ \\ \ \_/ \ \ \_\ \ \ \\ \      //
//       \ \____/ \ `\___/\ \____/\ \_\ \_\    //
//        \/___/   `\/__/  \/___/  \/_/\/ /    //
//                                             //
//                                             //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract Gen1 is ERC721Creator {
    constructor() ERC721Creator("Carlo Van de Roer - Modulator One", "Gen1") {}
}