// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Quiet Earth
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    The Quiet Earth    //
//                       //
//                       //
///////////////////////////


contract TQE is ERC721Creator {
    constructor() ERC721Creator("The Quiet Earth", "TQE") {}
}