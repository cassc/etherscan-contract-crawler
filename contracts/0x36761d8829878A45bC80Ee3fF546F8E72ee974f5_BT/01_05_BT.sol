// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Beat Totem
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//     Beat Totem © Roger Kilimanjaro - 2023    //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract BT is ERC1155Creator {
    constructor() ERC1155Creator("Beat Totem", "BT") {}
}