// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PLS&TY
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//                                               //
//        ____  __   _____ ___   ________  __    //
//       / __ \/ /  / ___/( _ ) /_  __/\ \/ /    //
//      / /_/ / /   \__ \/ __ \/|/ /    \  /     //
//     / ____/ /______/ / /_/  </ /     / /      //
//    /_/   /_____/____/\____/\/_/     /_/       //
//                                               //
//                                               //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract PLS is ERC1155Creator {
    constructor() ERC1155Creator("PLS&TY", "PLS") {}
}