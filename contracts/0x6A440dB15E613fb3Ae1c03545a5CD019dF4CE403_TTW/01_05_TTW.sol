// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Tweeds
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////
//                  //
//                  //
//    The Tweeds    //
//                  //
//                  //
//////////////////////


contract TTW is ERC1155Creator {
    constructor() ERC1155Creator("The Tweeds", "TTW") {}
}