// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LOVE*
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//     _     ____  _     _____          //
//    / \   /  _ \/ \ |\/  __/_/||\_    //
//    | |   | / \|| | //|  \  \    /    //
//    | |_/\| \_/|| \// |  /_ /    \    //
//    \____/\____/\__/  \____\ \||/     //
//                                      //
//                                      //
//////////////////////////////////////////


contract LOVE is ERC721Creator {
    constructor() ERC721Creator("LOVE*", "LOVE") {}
}