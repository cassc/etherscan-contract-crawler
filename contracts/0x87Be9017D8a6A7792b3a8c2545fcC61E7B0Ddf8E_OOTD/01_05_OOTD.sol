// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: #ootd
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    #ootd    //
//             //
//             //
/////////////////


contract OOTD is ERC721Creator {
    constructor() ERC721Creator("#ootd", "OOTD") {}
}