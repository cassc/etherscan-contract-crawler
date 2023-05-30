// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PAJIRO PASS GENESIS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////
//                  //
//                  //
//    pajiro.eth    //
//                  //
//                  //
//////////////////////


contract PJR is ERC1155Creator {
    constructor() ERC1155Creator("PAJIRO PASS GENESIS", "PJR") {}
}