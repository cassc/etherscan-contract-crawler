// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mya Parker
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////
//                  //
//                  //
//    Mya Parker    //
//                  //
//                  //
//////////////////////


contract SN is ERC1155Creator {
    constructor() ERC1155Creator("Mya Parker", "SN") {}
}