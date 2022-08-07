// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Late Night Thoughts
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//     ▄▄▄▄▄▄▄ ▄▄    ▄ ▄▄▄▄     //
//    █       █  █  █ █    █    //
//    █   ▄   █   █▄█ ██   █    //
//    █  █▄█  █       ██   █    //
//    █       █  ▄    ██   █    //
//    █   ▄   █ █ █   ██   █    //
//    █▄▄█ █▄▄█▄█  █▄▄██▄▄▄█    //
//                              //
//                              //
//////////////////////////////////


contract AN1 is ERC721Creator {
    constructor() ERC721Creator("Late Night Thoughts", "AN1") {}
}