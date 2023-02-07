// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ALI'S CHARITY
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////
//                               //
//                               //
//    SYRIA/TURKEY FUNDRAISER    //
//                               //
//                               //
///////////////////////////////////


contract ALI is ERC1155Creator {
    constructor() ERC1155Creator("ALI'S CHARITY", "ALI") {}
}