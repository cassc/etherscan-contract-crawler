// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Figura by ETG
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////
//                    //
//                    //
//                    //
//       ____         //
//      / _(_)__ _    //
//     / _/ / _ `/    //
//    /_//_/\_, /     //
//         /___/      //
//                    //
//                    //
//                    //
////////////////////////


contract FIG is ERC1155Creator {
    constructor() ERC1155Creator("Figura by ETG", "FIG") {}
}