// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Return of the Chess Queen
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//    Return of the Chess Queen    //
//                                 //
//                                 //
/////////////////////////////////////


contract RCQ is ERC1155Creator {
    constructor() ERC1155Creator("Return of the Chess Queen", "RCQ") {}
}