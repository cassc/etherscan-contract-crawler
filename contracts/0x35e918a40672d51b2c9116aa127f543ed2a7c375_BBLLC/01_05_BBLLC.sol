// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BadBeanLLC
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//                                                //
//                                                //
//     +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+    //
//     |B| |a| |d| |B| |e| |a| |n| |L| |L| |C|    //
//     +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+    //
//                                                //
//                                                //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract BBLLC is ERC1155Creator {
    constructor() ERC1155Creator("BadBeanLLC", "BBLLC") {}
}