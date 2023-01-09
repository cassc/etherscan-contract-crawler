// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Coregate Doge
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    Coregate super doge    //
//                           //
//                           //
///////////////////////////////


contract CORE is ERC721Creator {
    constructor() ERC721Creator("Coregate Doge", "CORE") {}
}