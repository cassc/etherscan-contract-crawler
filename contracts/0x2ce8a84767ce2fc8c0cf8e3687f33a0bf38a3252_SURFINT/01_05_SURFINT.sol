// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Surface Interventions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    // LB //    //
//                //
//                //
////////////////////


contract SURFINT is ERC721Creator {
    constructor() ERC721Creator("Surface Interventions", "SURFINT") {}
}