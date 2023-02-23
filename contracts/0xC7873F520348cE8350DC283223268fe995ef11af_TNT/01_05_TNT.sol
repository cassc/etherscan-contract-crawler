// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tokens N' Tunes!
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//     __       __            __      //
//    |__) \ / |__) | |    | /__`     //
//    |     |  |  \ | |___ | .__/     //
//                                    //
//                                    //
//                                    //
////////////////////////////////////////


contract TNT is ERC721Creator {
    constructor() ERC721Creator("Tokens N' Tunes!", "TNT") {}
}