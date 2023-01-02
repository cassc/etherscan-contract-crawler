// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LastLeaf Open Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//     ___      ___      _______  _______     //
//    |   |    |   |    |       ||       |    //
//    |   |    |   |    |   _   ||    ___|    //
//    |   |    |   |    |  | |  ||   |___     //
//    |   |___ |   |___ |  |_|  ||    ___|    //
//    |       ||       ||       ||   |___     //
//    |_______||_______||_______||_______|    //
//                                            //
//                                            //
////////////////////////////////////////////////


contract LLOE is ERC1155Creator {
    constructor() ERC1155Creator("LastLeaf Open Editions", "LLOE") {}
}