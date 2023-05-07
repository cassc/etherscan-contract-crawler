// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Gami
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    ⌐◨-◨    //
//            //
//            //
////////////////


contract GAMI is ERC721Creator {
    constructor() ERC721Creator("Gami", "GAMI") {}
}