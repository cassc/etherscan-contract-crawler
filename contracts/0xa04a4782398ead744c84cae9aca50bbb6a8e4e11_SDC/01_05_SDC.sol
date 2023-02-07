// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SudoChecks
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////
//                           //
//                           //
//    |5 1 3|6 8 7|2 4 9|    //
//    |8 4 9|5 2 1|6 3 7|    //
//    |2 6 7|3 4 9|5 8 1|    //
//    +-----+-----+-----+    //
//    |1 5 8|4 6 3|9 7 2|    //
//    |9 7 4|2 1 8|3 6 5|    //
//    |3 2 6|7 9 5|4 1 8|    //
//    +-----+-----+-----+    //
//    |7 8 2|9 3 4|1 5 6|    //
//    |6 3 5|1 7 2|8 9 4|    //
//    |4 9 1|8 5 6|7 2 3|    //
//                           //
//                           //
///////////////////////////////


contract SDC is ERC1155Creator {
    constructor() ERC1155Creator("SudoChecks", "SDC") {}
}