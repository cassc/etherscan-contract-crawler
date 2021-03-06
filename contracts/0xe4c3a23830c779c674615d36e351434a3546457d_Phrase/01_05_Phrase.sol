// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: P-hrase
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////
//                                                                           //
//                                                                           //
//                                                                           //
//    $$$$$$$\          $$\                                                  //
//    $$  __$$\         $$ |                                                 //
//    $$ |  $$ |        $$$$$$$\   $$$$$$\  $$$$$$\   $$$$$$$\  $$$$$$\      //
//    $$$$$$$  |$$$$$$\ $$  __$$\ $$  __$$\ \____$$\ $$  _____|$$  __$$\     //
//    $$  ____/ \______|$$ |  $$ |$$ |  \__|$$$$$$$ |\$$$$$$\  $$$$$$$$ |    //
//    $$ |              $$ |  $$ |$$ |     $$  __$$ | \____$$\ $$   ____|    //
//    $$ |              $$ |  $$ |$$ |     \$$$$$$$ |$$$$$$$  |\$$$$$$$\     //
//    \__|              \__|  \__|\__|      \_______|\_______/  \_______|    //
//                                                                           //
//                                                                           //
//                                                                           //
//                                                                           //
//                                                                           //
//                                                                           //
///////////////////////////////////////////////////////////////////////////////


contract Phrase is ERC721Creator {
    constructor() ERC721Creator("P-hrase", "Phrase") {}
}