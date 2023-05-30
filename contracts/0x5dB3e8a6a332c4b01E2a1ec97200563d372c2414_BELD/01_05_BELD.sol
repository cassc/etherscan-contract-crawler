// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bidders edition Laundry day
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////
//                              //
//                              //
//                              //
//        __    ___   __  __    //
//       / /   /   | / / / /    //
//      / /   / /| |/ / / /     //
//     / /___/ ___ / /_/ /      //
//    /_____/_/  |_\____/       //
//                              //
//                              //
//                              //
//                              //
//////////////////////////////////


contract BELD is ERC1155Creator {
    constructor() ERC1155Creator("Bidders edition Laundry day", "BELD") {}
}