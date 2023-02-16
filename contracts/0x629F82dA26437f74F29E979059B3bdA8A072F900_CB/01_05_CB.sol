// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Community Building
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//                            //
//    ___________________     //
//    \_   ___ \______   \    //
//    /    \  \/|    |  _/    //
//    \     \___|    |   \    //
//     \______  /______  /    //
//            \/       \/     //
//                            //
//                            //
////////////////////////////////


contract CB is ERC721Creator {
    constructor() ERC721Creator("Community Building", "CB") {}
}