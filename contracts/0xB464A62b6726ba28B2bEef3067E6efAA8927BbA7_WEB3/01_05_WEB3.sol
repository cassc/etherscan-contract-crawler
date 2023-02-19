// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Web -3
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//    ██    ██  ██████  ██ ██████      //
//    ██    ██ ██    ██ ██ ██   ██     //
//    ██    ██ ██    ██ ██ ██   ██     //
//     ██  ██  ██    ██ ██ ██   ██     //
//      ████    ██████  ██ ██████      //
//                                     //
//                                     //
/////////////////////////////////////////


contract WEB3 is ERC721Creator {
    constructor() ERC721Creator("Web -3", "WEB3") {}
}