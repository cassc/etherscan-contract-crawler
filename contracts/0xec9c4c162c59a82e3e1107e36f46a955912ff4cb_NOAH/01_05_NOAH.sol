// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NOAH
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//                  |           |           //
//    /~~/~~||/~\   |_//~~|\  /~|~/~~|~/    //
//    \__\__||   |  | \\__| \/  | \__|/_    //
//                         _/               //
//                                          //
//                                          //
//////////////////////////////////////////////


contract NOAH is ERC721Creator {
    constructor() ERC721Creator("NOAH", "NOAH") {}
}