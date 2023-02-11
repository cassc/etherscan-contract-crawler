// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hall of KaiSERx
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////
//                             //
//                             //
//                             //
//     _  _  __  _   _         //
//    | || |/  \| | | |        //
//    | >< | /\ | |_| |_  x    //
//    |_||_|_||_|___|___|      //
//                             //
//                             //
//                             //
/////////////////////////////////


contract HALL is ERC1155Creator {
    constructor() ERC1155Creator("Hall of KaiSERx", "HALL") {}
}