// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: #FI3ND
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    ?FORF?    //
//              //
//              //
//////////////////


contract FND is ERC721Creator {
    constructor() ERC721Creator("#FI3ND", "FND") {}
}