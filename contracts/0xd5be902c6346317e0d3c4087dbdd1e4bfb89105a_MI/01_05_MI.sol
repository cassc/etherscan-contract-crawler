// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GONNA
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////
//          //
//          //
//    ss    //
//          //
//          //
//////////////


contract MI is ERC721Creator {
    constructor() ERC721Creator("GONNA", "MI") {}
}