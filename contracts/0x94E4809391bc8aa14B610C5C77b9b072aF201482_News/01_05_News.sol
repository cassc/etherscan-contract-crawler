// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The News
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////
//                  //
//                  //
//    Newsletter    //
//                  //
//                  //
//////////////////////


contract News is ERC1155Creator {
    constructor() ERC1155Creator("The News", "News") {}
}