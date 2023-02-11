// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ORDINAL TELEPORT - BURN TO BRIDGE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//     $$$$$$\ $$$$$$$$\ $$$$$$$\      //
//    $$  __$$\\__$$  __|$$  __$$\     //
//    $$ /  $$ |  $$ |   $$ |  $$ |    //
//    $$ |  $$ |  $$ |   $$$$$$$\ |    //
//    $$ |  $$ |  $$ |   $$  __$$\     //
//    $$ |  $$ |  $$ |   $$ |  $$ |    //
//     $$$$$$  |  $$ |   $$$$$$$  |    //
//     \______/   \__|   \_______/     //
//                                     //
//                                     //
/////////////////////////////////////////


contract OTB is ERC1155Creator {
    constructor() ERC1155Creator("ORDINAL TELEPORT - BURN TO BRIDGE", "OTB") {}
}