// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BORABORA.art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    BORABORA.art    //
//                    //
//                    //
////////////////////////


contract BORABORA is ERC721Creator {
    constructor() ERC721Creator("BORABORA.art", "BORABORA") {}
}