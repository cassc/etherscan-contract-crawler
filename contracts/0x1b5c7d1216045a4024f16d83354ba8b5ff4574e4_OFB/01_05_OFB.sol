// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ovie Fanboy
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//     $$$$$$\  $$$$$$$$\ $$$$$$$\      //
//    $$  __$$\ $$  _____|$$  __$$\     //
//    $$ /  $$ |$$ |      $$ |  $$ |    //
//    $$ |  $$ |$$$$$\    $$$$$$$\ |    //
//    $$ |  $$ |$$  __|   $$  __$$\     //
//    $$ |  $$ |$$ |      $$ |  $$ |    //
//     $$$$$$  |$$ |      $$$$$$$  |    //
//     \______/ \__|      \_______/     //
//                                      //
//                                      //
//                                      //
//                                      //
//                                      //
//////////////////////////////////////////


contract OFB is ERC1155Creator {
    constructor() ERC1155Creator("Ovie Fanboy", "OFB") {}
}