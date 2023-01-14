// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Chime In
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////
//                           //
//                           //
//    0xdesigner was here    //
//                           //
//                           //
///////////////////////////////


contract CHIME is ERC1155Creator {
    constructor() ERC1155Creator("Chime In", "CHIME") {}
}