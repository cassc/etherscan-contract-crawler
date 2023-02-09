// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Weed Checks W
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////
//                  //
//                  //
//    WeedChecks    //
//                  //
//                  //
//////////////////////


contract WDCHKS is ERC1155Creator {
    constructor() ERC1155Creator("Weed Checks W", "WDCHKS") {}
}