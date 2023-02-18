// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: License to Blur
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////
//                          //
//                          //
//     __    ___   ____     //
//    (  )  (__ \ (  _ \    //
//     )(__  / _/  ) _ <    //
//    (____)(____)(____/    //
//                          //
//                          //
//////////////////////////////


contract LTB is ERC1155Creator {
    constructor() ERC1155Creator("License to Blur", "LTB") {}
}