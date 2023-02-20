// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cold
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//     .---.  .----. .-.   .----.     //
//    /  ___}/  {}  \| |   | {}  \    //
//    \     }\      /| `--.|     /    //
//     `---'  `----' `----'`----'     //
//                                    //
//                                    //
////////////////////////////////////////


contract CLD is ERC721Creator {
    constructor() ERC721Creator("Cold", "CLD") {}
}