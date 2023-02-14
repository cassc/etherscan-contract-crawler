// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Out-Game Flowers (Large Bouquets)
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//                _                    _     _     //
//               | |                  | |   | |    //
//      __ _ _ __| |___      __   _ __| | __| |    //
//     / _` | '__| __\ \ /\ / /  | '__| |/ _` |    //
//    | (_| | |  | |_ \ V  V /   | |  | | (_| |    //
//     \__,_|_|   \__| \_/\_/    |_|  |_|\__,_|    //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract OGFl is ERC721Creator {
    constructor() ERC721Creator("Out-Game Flowers (Large Bouquets)", "OGFl") {}
}