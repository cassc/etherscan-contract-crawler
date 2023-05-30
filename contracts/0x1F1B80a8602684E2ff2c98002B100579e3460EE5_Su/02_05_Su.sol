// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SuPostill
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    🌸~ SuPostill ~🌸    //
//                         //
//                         //
/////////////////////////////


contract Su is ERC721Creator {
    constructor() ERC721Creator("SuPostill", "Su") {}
}