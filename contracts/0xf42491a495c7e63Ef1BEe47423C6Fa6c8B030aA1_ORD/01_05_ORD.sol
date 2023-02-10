// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Not An Ordinal
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    <>This is not an Ordinal    //
//                                //
//    <>6969 Supply               //
//                                //
//                                //
////////////////////////////////////


contract ORD is ERC1155Creator {
    constructor() ERC1155Creator("Not An Ordinal", "ORD") {}
}