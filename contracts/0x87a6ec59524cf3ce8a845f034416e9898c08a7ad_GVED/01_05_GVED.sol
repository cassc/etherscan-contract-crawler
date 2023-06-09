// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Garvanti editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////
//          //
//          //
//    :)    //
//          //
//          //
//////////////


contract GVED is ERC721Creator {
    constructor() ERC721Creator("Garvanti editions", "GVED") {}
}