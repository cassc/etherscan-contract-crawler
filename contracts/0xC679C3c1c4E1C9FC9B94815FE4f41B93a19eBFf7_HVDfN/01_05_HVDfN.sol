// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Love Letter from Nadobroart
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////
//                  //
//                  //
//    nadobroart    //
//                  //
//                  //
//////////////////////


contract HVDfN is ERC1155Creator {
    constructor() ERC1155Creator("Love Letter from Nadobroart", "HVDfN") {}
}