// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FatTest
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////
//          //
//          //
//    FU    //
//          //
//          //
//////////////


contract FUTEST is ERC721Creator {
    constructor() ERC721Creator("FatTest", "FUTEST") {}
}