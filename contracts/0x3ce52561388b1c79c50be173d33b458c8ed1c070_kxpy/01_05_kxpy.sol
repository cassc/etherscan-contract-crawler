// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: kxpy
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    我是你爹 over    //
//                 //
//                 //
/////////////////////


contract kxpy is ERC721Creator {
    constructor() ERC721Creator("kxpy", "kxpy") {}
}