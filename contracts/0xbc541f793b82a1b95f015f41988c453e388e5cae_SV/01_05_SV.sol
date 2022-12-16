// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: stefvisual
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//    ░█▀▀░▀█▀░█▀▀░█▀▀    //
//    ░▀▀█░░█░░█▀▀░█▀▀    //
//    ░▀▀▀░░▀░░▀▀▀░▀░░    //
//                        //
//                        //
////////////////////////////


contract SV is ERC721Creator {
    constructor() ERC721Creator("stefvisual", "SV") {}
}