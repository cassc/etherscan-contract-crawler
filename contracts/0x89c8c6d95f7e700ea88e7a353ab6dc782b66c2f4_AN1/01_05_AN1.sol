// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AN1 1/1
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
    constructor() ERC721Creator("AN1 1/1", "AN1") {}
}