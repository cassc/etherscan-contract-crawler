// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: D1V1NE
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


contract D1V is ERC721Creator {
    constructor() ERC721Creator("D1V1NE", "D1V") {}
}