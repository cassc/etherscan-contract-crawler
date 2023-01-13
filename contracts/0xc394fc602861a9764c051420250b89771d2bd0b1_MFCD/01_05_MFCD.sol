// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MfersCard
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//    By BLeo. You can do everything     //
//                                       //
//                                       //
///////////////////////////////////////////


contract MFCD is ERC1155Creator {
    constructor() ERC1155Creator("MfersCard", "MFCD") {}
}