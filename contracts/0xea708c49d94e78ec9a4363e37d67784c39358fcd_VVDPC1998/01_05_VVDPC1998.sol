// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: VVD Post Card (1988)
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////
//                    //
//                    //
//    [🐸📫📪📬📭]    //
//                    //
//                    //
////////////////////////


contract VVDPC1998 is ERC1155Creator {
    constructor() ERC1155Creator("VVD Post Card (1988)", "VVDPC1998") {}
}