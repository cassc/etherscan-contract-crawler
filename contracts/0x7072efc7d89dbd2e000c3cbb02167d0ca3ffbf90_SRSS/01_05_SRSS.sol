// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Secret Santa
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    Priceless    //
//                 //
//                 //
/////////////////////


contract SRSS is ERC721Creator {
    constructor() ERC721Creator("Secret Santa", "SRSS") {}
}