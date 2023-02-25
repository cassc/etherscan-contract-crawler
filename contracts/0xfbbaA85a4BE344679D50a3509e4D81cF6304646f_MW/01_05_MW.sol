// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: my world of flowers
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    my world of flowers    //
//                           //
//                           //
///////////////////////////////


contract MW is ERC721Creator {
    constructor() ERC721Creator("my world of flowers", "MW") {}
}