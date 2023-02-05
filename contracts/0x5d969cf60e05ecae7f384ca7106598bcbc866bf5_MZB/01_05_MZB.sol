// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mao ZeBalloon
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//    Are you the needle or the balloon    //
//                                         //
//                                         //
/////////////////////////////////////////////


contract MZB is ERC1155Creator {
    constructor() ERC1155Creator("Mao ZeBalloon", "MZB") {}
}