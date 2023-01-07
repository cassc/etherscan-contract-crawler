// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mansions Edition
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//    Bidder/Holder Special Edition    //
//                                     //
//                                     //
/////////////////////////////////////////


contract ME is ERC1155Creator {
    constructor() ERC1155Creator("Mansions Edition", "ME") {}
}