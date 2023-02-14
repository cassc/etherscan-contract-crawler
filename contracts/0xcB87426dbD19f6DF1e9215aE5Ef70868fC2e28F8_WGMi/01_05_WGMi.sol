// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WGMi
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//     _     _  _______  __   __  ___        //
//    | | _ | ||       ||  |_|  ||   |       //
//    | || || ||    ___||       ||   |       //
//    |       ||   | __ |       ||   |       //
//    |       ||   ||  ||       ||   |       //
//    |   _   ||   |_| || ||_|| ||   |       //
//    |__| |__||_______||_|   |_||___|       //
//                                           //
//                                           //
///////////////////////////////////////////////


contract WGMi is ERC721Creator {
    constructor() ERC721Creator("WGMi", "WGMi") {}
}