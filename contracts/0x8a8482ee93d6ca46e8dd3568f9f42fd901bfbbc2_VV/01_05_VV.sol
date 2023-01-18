// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Checks VV Community Space
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////
//                 //
//                 //
//    Checks VV    //
//                 //
//                 //
/////////////////////


contract VV is ERC1155Creator {
    constructor() ERC1155Creator("Checks VV Community Space", "VV") {}
}