// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FRSGHTD
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////
//                  //
//                  //
//    keep going    //
//                  //
//                  //
//////////////////////


contract FRSGHTD is ERC1155Creator {
    constructor() ERC1155Creator("FRSGHTD", "FRSGHTD") {}
}