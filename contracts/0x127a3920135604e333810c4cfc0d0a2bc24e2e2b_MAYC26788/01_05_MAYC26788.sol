// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: #26788
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    #26788    //
//              //
//              //
//////////////////


contract MAYC26788 is ERC721Creator {
    constructor() ERC721Creator("#26788", "MAYC26788") {}
}