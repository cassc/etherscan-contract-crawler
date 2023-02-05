// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Anonymous Gift
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//     ██████  ██   ██ ██ ██ ███    ██     //
//    ██    ██ ██  ██  ██ ██ ████   ██     //
//    ██    ██ █████   ██ ██ ██ ██  ██     //
//    ██    ██ ██  ██  ██ ██ ██  ██ ██     //
//     ██████  ██   ██ ██ ██ ██   ████     //
//                                         //
//                                         //
/////////////////////////////////////////////


contract GIFT is ERC1155Creator {
    constructor() ERC1155Creator("Anonymous Gift", "GIFT") {}
}