// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Silent scream
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//                                           //
//                                           //
//                  _                        //
//                 | |                       //
//       __ _ _ __ | |_ _ __   __ _  ___     //
//      / _` | '_ \| __| '_ \ / _` |/ _ \    //
//     | (_| | |_) | |_| | | | (_| |  __/    //
//      \__,_| .__/ \__|_| |_|\__,_|\___|    //
//           | |                             //
//           |_|                             //
//                                           //
//                                           //
//                                           //
//                                           //
///////////////////////////////////////////////


contract aptnae is ERC721Creator {
    constructor() ERC721Creator("Silent scream", "aptnae") {}
}