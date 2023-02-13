// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SPACE X DOGE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////
//                    //
//                    //
//    SPACE X DOGE    //
//                    //
//                    //
////////////////////////


contract XDOGE is ERC1155Creator {
    constructor() ERC1155Creator("SPACE X DOGE", "XDOGE") {}
}