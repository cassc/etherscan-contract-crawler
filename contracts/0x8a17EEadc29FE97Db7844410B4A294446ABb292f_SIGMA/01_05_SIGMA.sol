// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Σ
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


contract SIGMA is ERC1155Creator {
    constructor() ERC1155Creator(unicode"Σ", "SIGMA") {}
}