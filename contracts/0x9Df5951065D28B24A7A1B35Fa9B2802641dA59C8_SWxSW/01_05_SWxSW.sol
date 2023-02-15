// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sarah Words x Sarah Woods
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//     ____  _  _  _  _  ____  _  _     //
//    / ___)/ )( \( \/ )/ ___)/ )( \    //
//    \___ \\ /\ / )  ( \___ \\ /\ /    //
//    (____/(_/\_)(_/\_)(____/(_/\_)    //
//                                      //
//                                      //
//////////////////////////////////////////


contract SWxSW is ERC1155Creator {
    constructor() ERC1155Creator("Sarah Words x Sarah Woods", "SWxSW") {}
}