// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: META∞MANTRA
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//                                                          //
//           ___ ___                      ___  __           //
//     |\/| |__   |   /\   |\/|  /\  |\ |  |  |__)  /\      //
//     |  | |___  |  /~~\  |  | /~~\ | \|  |  |  \ /~~\     //
//                                                          //
//                                                          //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract META is ERC721Creator {
    constructor() ERC721Creator(unicode"META∞MANTRA", "META") {}
}