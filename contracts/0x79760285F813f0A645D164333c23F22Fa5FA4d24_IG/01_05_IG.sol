// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: idol generative
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////
//          //
//          //
//    IG    //
//          //
//          //
//////////////


contract IG is ERC721Creator {
    constructor() ERC721Creator("idol generative", "IG") {}
}