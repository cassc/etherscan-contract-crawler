// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FDR 2020
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//    ██████   ██████  ██████   ██████      //
//         ██ ██  ████      ██ ██  ████     //
//     █████  ██ ██ ██  █████  ██ ██ ██     //
//    ██      ████  ██ ██      ████  ██     //
//    ███████  ██████  ███████  ██████      //
//                                          //
//                                          //
//                                          //
//////////////////////////////////////////////


contract FDR is ERC1155Creator {
    constructor() ERC1155Creator("FDR 2020", "FDR") {}
}