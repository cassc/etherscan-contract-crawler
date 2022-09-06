// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Test Contrato
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//    ──────▄▀▄─────▄▀▄          //
//    ─────▄█░░▀▀▀▀▀░░█▄         //
//    ─▄▄──█░░░░░░░░░░░█──▄▄     //
//    █▄▄█─█░░▀░░┬░░▀░░█─█▄▄█    //
//                               //
//                               //
//                               //
///////////////////////////////////


contract TC is ERC721Creator {
    constructor() ERC721Creator("Test Contrato", "TC") {}
}