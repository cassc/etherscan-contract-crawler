// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AFox-Manifold
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    AFOXINWEB3    //
//                  //
//                  //
//////////////////////


contract AFOXM is ERC721Creator {
    constructor() ERC721Creator("AFox-Manifold", "AFOXM") {}
}