// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tsrif
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//                                 //
//    █     ▄█▄    ██       ▄      //
//    █     █▀ ▀▄  █ █  ▀▄   █     //
//    █     █   ▀  █▄▄█   █ ▀      //
//    ███▄  █▄  ▄▀ █  █  ▄ █       //
//        ▀ ▀███▀     █ █   ▀▄     //
//                   █   ▀         //
//                  ▀              //
//                                 //
//                                 //
//                                 //
/////////////////////////////////////


contract Tsrif is ERC1155Creator {
    constructor() ERC1155Creator("Tsrif", "Tsrif") {}
}