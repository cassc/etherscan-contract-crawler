// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Peaceful Slimes
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//                                                //
//                                                //
//                                                //
//                   OOOOOOOOOO                   //
//               OOOOOOOOOOOOOOOOOO               //
//             OOOOOOOOOOOOOOOOOOOOOO             //
//           OOOOOOOOOOOOOOOOOOOOOOOOOO           //
//          OOOOOOOOOOOOOOOOOOOOOOOOOOOO          //
//          OOOOOOOOOOOOOOOOOOOOOOOOOOOO          //
//         OOOOOOOOOOOOOOOOOOOOOOOOOOOOOO         //
//         OOOOOOOOOOOOOOOOOOOOOOOOOOOOOO         //
//          OOOOOOOOOOOOOOOOOOOOOOOOOOOO          //
//          OOOOOOOOOOOOOOOOOOOOOOOOOOOO          //
//           OOOOOOOOOOOOOOOOOOOOOOOOOO           //
//             OOOOOOOOOOOOOOOOOOOOOO             //
//               OOOOOOOOOOOOOOOOOO               //
//                   OOOOOOOOOO                   //
//                                                //
//                                                //
//                                                //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract SLIME1 is ERC721Creator {
    constructor() ERC721Creator("Peaceful Slimes", "SLIME1") {}
}