// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Editions by Chakrit_L
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////
//                      //
//                      //
//    //////////////    //
//    //          //    //
//    //          //    //
//    //    CL    //    //
//    //          //    //
//    //          //    //
//    //////////////    //
//                      //
//                      //
//////////////////////////


contract CL is ERC1155Creator {
    constructor() ERC1155Creator("Editions by Chakrit_L", "CL") {}
}