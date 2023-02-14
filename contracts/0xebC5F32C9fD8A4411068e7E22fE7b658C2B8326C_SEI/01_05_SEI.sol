// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: POSEIDON
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////
//                      //
//                      //
//                      //
//      __  ___ ___     //
//     (_ ` )_   )      //
//    .__) (__ _(_      //
//                      //
//                      //
//                      //
//////////////////////////


contract SEI is ERC1155Creator {
    constructor() ERC1155Creator("POSEIDON", "SEI") {}
}