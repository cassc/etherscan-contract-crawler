// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SMOLEDITION
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//    SOME SMOLS TO BURN, SOME SMOLS TO HODL.    //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract SMLD is ERC1155Creator {
    constructor() ERC1155Creator("SMOLEDITION", "SMLD") {}
}