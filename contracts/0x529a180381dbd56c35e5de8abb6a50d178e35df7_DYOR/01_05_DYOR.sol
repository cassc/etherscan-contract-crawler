// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NFA DYOR
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////
//                //
//                //
//    NFA DYOR    //
//                //
//                //
////////////////////


contract DYOR is ERC1155Creator {
    constructor() ERC1155Creator("NFA DYOR", "DYOR") {}
}