// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Long Live Zug
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//    Free claim to commemorate the end of Ether Orcs.     //
//                                                         //
//    2.6.22                                               //
//                                                         //
//    Long.Live.Zug                                        //
//                                                         //
//                                                         //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract ZUG is ERC1155Creator {
    constructor() ERC1155Creator("Long Live Zug", "ZUG") {}
}