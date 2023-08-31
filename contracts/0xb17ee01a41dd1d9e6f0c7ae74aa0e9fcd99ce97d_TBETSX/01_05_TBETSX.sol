// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Blockchain Experience Times Square Takeover
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//    The Blockchain Experience Times Square Takeover    //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract TBETSX is ERC1155Creator {
    constructor() ERC1155Creator("The Blockchain Experience Times Square Takeover", "TBETSX") {}
}