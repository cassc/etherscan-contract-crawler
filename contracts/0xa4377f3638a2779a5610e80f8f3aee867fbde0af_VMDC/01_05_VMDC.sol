// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DIGITAL CERAMICS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//    VICTOR MOSQUERA \ DIGITAL CERAMICS     //
//                                           //
//                                           //
///////////////////////////////////////////////


contract VMDC is ERC1155Creator {
    constructor() ERC1155Creator("DIGITAL CERAMICS", "VMDC") {}
}