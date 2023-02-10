// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ordinal cats
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    ORDINAL CATS    //
//                    //
//                    //
////////////////////////


contract ORDC is ERC721Creator {
    constructor() ERC721Creator("Ordinal cats", "ORDC") {}
}