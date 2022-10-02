// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Landscapes by Korbinian Vogt
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//    Landscapes by Korbinian Vogt.    //
//                                     //
//                                     //
/////////////////////////////////////////


contract LBKV is ERC721Creator {
    constructor() ERC721Creator("Landscapes by Korbinian Vogt", "LBKV") {}
}