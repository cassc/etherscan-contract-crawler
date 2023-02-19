// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Web -3
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

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


contract WEBMINUS3 is ERC1155Creator {
    constructor() ERC1155Creator("Web -3", "WEBMINUS3") {}
}