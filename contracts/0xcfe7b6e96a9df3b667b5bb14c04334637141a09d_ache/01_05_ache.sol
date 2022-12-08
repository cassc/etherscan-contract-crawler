// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: achev
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    acheva    //
//              //
//              //
//////////////////


contract ache is ERC721Creator {
    constructor() ERC721Creator("achev", "ache") {}
}