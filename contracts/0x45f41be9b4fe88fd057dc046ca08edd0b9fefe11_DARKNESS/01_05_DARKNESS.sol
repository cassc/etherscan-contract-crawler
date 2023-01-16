// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DARKNESS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                          //
//                                                                                          //
//    What i tell you in darkness, that speak ye in light and what ye hear in the ear...    //
//                                                                                          //
//                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////


contract DARKNESS is ERC1155Creator {
    constructor() ERC1155Creator("DARKNESS", "DARKNESS") {}
}