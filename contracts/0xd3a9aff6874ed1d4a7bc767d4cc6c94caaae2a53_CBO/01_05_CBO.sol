// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Check Balloons Official
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    kekw    //
//            //
//            //
////////////////


contract CBO is ERC1155Creator {
    constructor() ERC1155Creator("Check Balloons Official", "CBO") {}
}