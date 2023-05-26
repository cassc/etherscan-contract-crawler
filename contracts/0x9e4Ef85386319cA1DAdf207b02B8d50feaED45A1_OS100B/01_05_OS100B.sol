// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: osushi-san 100 Birthday
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////
//                  //
//                  //
//    osushi-san    //
//                  //
//                  //
//////////////////////


contract OS100B is ERC1155Creator {
    constructor() ERC1155Creator("osushi-san 100 Birthday", "OS100B") {}
}