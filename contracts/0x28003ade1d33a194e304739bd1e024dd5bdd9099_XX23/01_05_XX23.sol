// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: XX23
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//    ██████   ██████  ██████  ██████      //
//         ██ ██  ████      ██      ██     //
//     █████  ██ ██ ██  █████   █████      //
//    ██      ████  ██ ██           ██     //
//    ███████  ██████  ███████ ██████      //
//                                         //
//                                         //
//                                         //
//                                         //
/////////////////////////////////////////////


contract XX23 is ERC721Creator {
    constructor() ERC721Creator("XX23", "XX23") {}
}