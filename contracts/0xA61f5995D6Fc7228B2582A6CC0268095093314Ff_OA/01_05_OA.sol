// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Old Art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    01?427X8    //
//                //
//                //
////////////////////


contract OA is ERC721Creator {
    constructor() ERC721Creator("Old Art", "OA") {}
}