// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Truth Be Told
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//     _______  ____   _______     //
//    |__   __||  _ \ |__   __|    //
//       | |   | |_) |   | |       //
//       | |   |  _ <    | |       //
//       | |   | |_) |   | |       //
//       |_|   |____/    |_|       //
//                                 //
//                                 //
//                                 //
//                                 //
//                                 //
/////////////////////////////////////


contract TBT is ERC721Creator {
    constructor() ERC721Creator("Truth Be Told", "TBT") {}
}