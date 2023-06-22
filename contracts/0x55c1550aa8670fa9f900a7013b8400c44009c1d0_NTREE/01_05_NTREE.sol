// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NFTrees
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//                                             //
//     _______  ______    _______  _______     //
//    |       ||    _ |  |       ||       |    //
//    |_     _||   | ||  |    ___||    ___|    //
//      |   |  |   |_||_ |   |___ |   |___     //
//      |   |  |    __  ||    ___||    ___|    //
//      |   |  |   |  | ||   |___ |   |___     //
//      |___|  |___|  |_||_______||_______|    //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract NTREE is ERC1155Creator {
    constructor() ERC1155Creator("NFTrees", "NTREE") {}
}