// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: INFINITE OF Humans
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//    ░▀█▀░█▀█░█▀▀░▀█▀░█▀█░▀█▀░▀█▀░█▀▀    //
//    ░░█░░█░█░█▀▀░░█░░█░█░░█░░░█░░█▀▀    //
//    ░▀▀▀░▀░▀░▀░░░▀▀▀░▀░▀░▀▀▀░░▀░░▀▀▀    //
//                                        //
//                                        //
////////////////////////////////////////////


contract IOH is ERC721Creator {
    constructor() ERC721Creator("INFINITE OF Humans", "IOH") {}
}