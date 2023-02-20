// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: @CheckGrandpepe
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    WAGMI     //
//              //
//              //
//////////////////


contract CGP is ERC721Creator {
    constructor() ERC721Creator("@CheckGrandpepe", "CGP") {}
}