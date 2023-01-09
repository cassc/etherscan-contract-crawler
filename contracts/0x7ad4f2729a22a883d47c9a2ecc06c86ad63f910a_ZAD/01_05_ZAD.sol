// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Zimordials
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////
//               //
//               //
//    ZZZZZZZ    //
//         Z     //
//        Z      //
//       Z       //
//      Z        //
//     Z         //
//    ZZZZZZZ    //
//               //
//               //
///////////////////


contract ZAD is ERC1155Creator {
    constructor() ERC1155Creator("Zimordials", "ZAD") {}
}