// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Life Beyond Time
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////
//                        //
//                        //
//    Life Beyond Time    //
//    |||PeterArt18|||    //
//                        //
//                        //
////////////////////////////


contract LBTPA is ERC1155Creator {
    constructor() ERC1155Creator("Life Beyond Time", "LBTPA") {}
}