// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Space
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//                                        //
//       _  __         _  __     _        //
//      / |/ ___ ____ / |/ ___  (_____    //
//     /    / _ `/_ //    / _ \/ / __/    //
//    /_/|_/\_,_//__/_/|_/\___/_/_/       //
//                                        //
//                                        //
//                                        //
//                                        //
////////////////////////////////////////////


contract Spce is ERC721Creator {
    constructor() ERC721Creator("Space", "Spce") {}
}