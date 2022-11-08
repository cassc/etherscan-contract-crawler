// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: real18nom
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    real18nom    //
//                 //
//                 //
/////////////////////


contract real is ERC721Creator {
    constructor() ERC721Creator("real18nom", "real") {}
}