// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GM CHECKS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////
//          //
//          //
//    GM    //
//          //
//          //
//////////////


contract GMC is ERC721Creator {
    constructor() ERC721Creator("GM CHECKS", "GMC") {}
}