// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NotRoccoHawk
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////
//                    //
//                    //
//     __________+    //
//    |  _       |    //
//    | | | |  | |    //
//    | |_| |__| |    //
//    | | \ |  | |    //
//    | |  ||  | |    //
//    |__________|    //
//     ____           //
//    |    |          //
//    |____|          //
//                    //
//                    //
////////////////////////


contract RHN is ERC1155Creator {
    constructor() ERC1155Creator("NotRoccoHawk", "RHN") {}
}