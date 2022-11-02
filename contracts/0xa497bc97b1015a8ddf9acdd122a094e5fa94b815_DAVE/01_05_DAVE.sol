// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Art by Dave.
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    Art by Dave.    //
//                    //
//                    //
////////////////////////


contract DAVE is ERC721Creator {
    constructor() ERC721Creator("Art by Dave.", "DAVE") {}
}