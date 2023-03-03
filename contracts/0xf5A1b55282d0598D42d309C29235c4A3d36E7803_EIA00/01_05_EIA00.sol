// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LOST/NOW DIGITAL
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//    if you are reading this i owe you a beer.     //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract EIA00 is ERC1155Creator {
    constructor() ERC1155Creator("LOST/NOW DIGITAL", "EIA00") {}
}