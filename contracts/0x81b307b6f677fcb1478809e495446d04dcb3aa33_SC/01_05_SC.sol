// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SmokersClub
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////
//                            //
//                            //
//    Welcome to club 69!     //
//                            //
//                            //
////////////////////////////////


contract SC is ERC1155Creator {
    constructor() ERC1155Creator("SmokersClub", "SC") {}
}