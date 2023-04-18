// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: non-fungible skier
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////
//                 //
//                 //
//    pSeudonym    //
//                 //
//       o         //
//      />         //
//     % \         //
//     __/__,      //
//                 //
//                 //
/////////////////////


contract NFS is ERC1155Creator {
    constructor() ERC1155Creator("non-fungible skier", "NFS") {}
}