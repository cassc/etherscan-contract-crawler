// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Holy Trinity by Tuan Jones
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    HOLY TRINITY by Tuan Jones    //
//                                  //
//                                  //
//////////////////////////////////////


contract HLYTRNTY is ERC1155Creator {
    constructor() ERC1155Creator("Holy Trinity by Tuan Jones", "HLYTRNTY") {}
}