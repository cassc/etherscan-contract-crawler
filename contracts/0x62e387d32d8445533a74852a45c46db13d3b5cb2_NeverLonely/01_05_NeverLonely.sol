// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LFLC_Community_Deployer_
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//     __        ________  __         ______      //
//    /  |      /        |/  |       /      \     //
//    $$ |      $$$$$$$$/ $$ |      /$$$$$$  |    //
//    $$ |      $$ |__    $$ |      $$ |  $$/     //
//    $$ |      $$    |   $$ |      $$ |          //
//    $$ |      $$$$$/    $$ |      $$ |   __     //
//    $$ |_____ $$ |      $$ |_____ $$ \__/  |    //
//    $$       |$$ |      $$       |$$    $$/     //
//    $$$$$$$$/ $$/       $$$$$$$$/  $$$$$$/      //
//                                                //
//                                                //
//                                                //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract NeverLonely is ERC1155Creator {
    constructor() ERC1155Creator("LFLC_Community_Deployer_", "NeverLonely") {}
}