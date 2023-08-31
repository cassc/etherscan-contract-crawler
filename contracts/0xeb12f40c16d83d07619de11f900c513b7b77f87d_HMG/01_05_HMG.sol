// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HAVAH MANIFOLD GENESIS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//    /////////////////////////////////    //
//    //  =========================  //    //
//    //  H     H V       V H     H  //    //
//    //  H     H  V     V  H     H  //    //
//    //  H H H H   V   V   H H H H  //    //
//    //  H     H    V V    H     H  //    //
//    //  H     H     V     H     H  //    //
//    //  =========================  //    //
//    /////////////////////////////////    //
//                                         //
//                                         //
/////////////////////////////////////////////


contract HMG is ERC1155Creator {
    constructor() ERC1155Creator("HAVAH MANIFOLD GENESIS", "HMG") {}
}