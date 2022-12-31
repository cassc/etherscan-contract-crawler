// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Take me to the ocean
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//                                      //
//     __             __   ___  ___     //
//    /__` |  | |\ | /__` |__  |__      //
//    .__/ \__/ | \| .__/ |___ |___     //
//                                      //
//                                      //
//                                      //
//                                      //
//////////////////////////////////////////


contract TMTTO is ERC1155Creator {
    constructor() ERC1155Creator("Take me to the ocean", "TMTTO") {}
}