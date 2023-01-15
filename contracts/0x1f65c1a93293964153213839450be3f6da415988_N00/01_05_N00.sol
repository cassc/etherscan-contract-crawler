// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nord
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    ▄▀▀▄ ▄▀▄  ▄▀▀▀▀▄          //
//    █  █ ▀  █ █    █          //
//    ▐  █    █ ▐    █          //
//      █    █      █           //
//    ▄▀   ▄▀     ▄▀▄▄▄▄▄▄▀     //
//    █    █      █             //
//    ▐    ▐      ▐             //
//                              //
//                              //
//////////////////////////////////


contract N00 is ERC721Creator {
    constructor() ERC721Creator("Nord", "N00") {}
}