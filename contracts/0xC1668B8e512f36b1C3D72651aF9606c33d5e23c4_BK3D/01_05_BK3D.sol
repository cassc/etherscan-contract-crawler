// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bakers 3D
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////
//                 //
//                 //
//    Bakers 3D    //
//                 //
//                 //
/////////////////////


contract BK3D is ERC1155Creator {
    constructor() ERC1155Creator("Bakers 3D", "BK3D") {}
}