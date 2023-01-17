// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: What if?
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    What if?    //
//                //
//                //
////////////////////


contract BOINE is ERC721Creator {
    constructor() ERC721Creator("What if?", "BOINE") {}
}