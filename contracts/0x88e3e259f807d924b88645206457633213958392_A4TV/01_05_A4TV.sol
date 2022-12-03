// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ArtsForTheVoid
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    to the Void together!    //
//                             //
//                             //
/////////////////////////////////


contract A4TV is ERC721Creator {
    constructor() ERC721Creator("ArtsForTheVoid", "A4TV") {}
}