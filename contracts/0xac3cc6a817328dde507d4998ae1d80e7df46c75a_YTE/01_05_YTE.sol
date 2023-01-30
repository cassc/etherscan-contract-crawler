// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Yunayuna x Tommy Edition
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//    January 30 is YunaYuna and Tommy's birthday!    //
//                                                    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract YTE is ERC1155Creator {
    constructor() ERC1155Creator("Yunayuna x Tommy Edition", "YTE") {}
}