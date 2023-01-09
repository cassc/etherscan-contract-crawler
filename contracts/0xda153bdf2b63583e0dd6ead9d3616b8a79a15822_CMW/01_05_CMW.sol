// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Chikakomei world
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////
//                   //
//                   //
//    Chikakokoko    //
//                   //
//                   //
///////////////////////


contract CMW is ERC1155Creator {
    constructor() ERC1155Creator("Chikakomei world", "CMW") {}
}