// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TCG
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//      _______ _____ _____     //
//     |__   __/ ____/ ____|    //
//        | | | |   | |  __     //
//        | | | |   | | |_ |    //
//        | | | |___| |__| |    //
//        |_|  \_____\_____|    //
//                              //
//                              //
//                              //
//////////////////////////////////


contract TCG is ERC721Creator {
    constructor() ERC721Creator("TCG", "TCG") {}
}