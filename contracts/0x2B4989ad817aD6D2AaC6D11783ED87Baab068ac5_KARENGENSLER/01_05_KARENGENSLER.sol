// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Karen Gensler
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////
//                         //
//                         //
//                         //
//                         //
//     _____     _____     //
//    |     |___|     |    //
//    |  |  |___|  |  |    //
//    |_____|   |_____|    //
//                         //
//                         //
//                         //
//                         //
/////////////////////////////


contract KARENGENSLER is ERC1155Creator {
    constructor() ERC1155Creator("Karen Gensler", "KARENGENSLER") {}
}