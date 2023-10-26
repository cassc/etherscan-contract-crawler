// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: marfa mirage
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//    🌵 a mirage in marfa 🌵    //
//                               //
//                               //
///////////////////////////////////


contract marfa is ERC721Creator {
    constructor() ERC721Creator("marfa mirage", "marfa") {}
}