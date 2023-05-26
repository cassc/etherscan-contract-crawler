// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Weird Cuts
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//             __   \|/    //
//    | |___| /  _|_-*-    //
//    |^(/(_| \_|_|_/|\    //
//                         //
//                         //
/////////////////////////////


contract WRD is ERC721Creator {
    constructor() ERC721Creator("Weird Cuts", "WRD") {}
}