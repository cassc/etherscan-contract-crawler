// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CURATIO PASS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//    CURATIO PASS BY KOLLECTOR    //
//                                 //
//                                 //
/////////////////////////////////////


contract CAP is ERC1155Creator {
    constructor() ERC1155Creator("CURATIO PASS", "CAP") {}
}