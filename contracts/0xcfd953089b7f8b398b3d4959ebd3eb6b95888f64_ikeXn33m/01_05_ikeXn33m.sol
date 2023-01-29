// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ikehaya x N33M pass
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    <3 no utility, just a pass    //
//                                  //
//                                  //
//////////////////////////////////////


contract ikeXn33m is ERC1155Creator {
    constructor() ERC1155Creator("ikehaya x N33M pass", "ikeXn33m") {}
}