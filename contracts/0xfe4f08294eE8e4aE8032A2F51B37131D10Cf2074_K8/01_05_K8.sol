// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BLACK HAT K
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    BlackHat    //
//                //
//                //
////////////////////


contract K8 is ERC721Creator {
    constructor() ERC721Creator("BLACK HAT K", "K8") {}
}