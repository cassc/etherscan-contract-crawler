// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ALPHA-01
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    -------- X --------    //
//                           //
//                           //
///////////////////////////////


contract ALPHA is ERC721Creator {
    constructor() ERC721Creator("ALPHA-01", "ALPHA") {}
}