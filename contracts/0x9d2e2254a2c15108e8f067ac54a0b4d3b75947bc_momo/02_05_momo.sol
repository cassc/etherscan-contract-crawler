// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: momo Pass
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//                                         //
//                                         //
//                                         //
//     _ __ ___   ___  _ __ ___   ___      //
//    | '_ ` _ \ / _ \| '_ ` _ \ / _ \     //
//    | | | | | | (_) | | | | | | (_) |    //
//    |_| |_| |_|\___/|_| |_| |_|\___/     //
//                                         //
//                                         //
//                                         //
//                                         //
//                                         //
/////////////////////////////////////////////


contract momo is ERC1155Creator {
    constructor() ERC1155Creator("momo Pass", "momo") {}
}