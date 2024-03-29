// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PutDickInside
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                            //
//                                                                                                                            //
//                                                                                                                            //
//    $$$$$$$\              $$\     $$$$$$$\  $$\           $$\       $$$$$$\                     $$\       $$\               //
//    $$  __$$\             $$ |    $$  __$$\ \__|          $$ |      \_$$  _|                    \__|      $$ |              //
//    $$ |  $$ |$$\   $$\ $$$$$$\   $$ |  $$ |$$\  $$$$$$$\ $$ |  $$\   $$ |  $$$$$$$\   $$$$$$$\ $$\  $$$$$$$ | $$$$$$\      //
//    $$$$$$$  |$$ |  $$ |\_$$  _|  $$ |  $$ |$$ |$$  _____|$$ | $$  |  $$ |  $$  __$$\ $$  _____|$$ |$$  __$$ |$$  __$$\     //
//    $$  ____/ $$ |  $$ |  $$ |    $$ |  $$ |$$ |$$ /      $$$$$$  /   $$ |  $$ |  $$ |\$$$$$$\  $$ |$$ /  $$ |$$$$$$$$ |    //
//    $$ |      $$ |  $$ |  $$ |$$\ $$ |  $$ |$$ |$$ |      $$  _$$<    $$ |  $$ |  $$ | \____$$\ $$ |$$ |  $$ |$$   ____|    //
//    $$ |      \$$$$$$  |  \$$$$  |$$$$$$$  |$$ |\$$$$$$$\ $$ | \$$\ $$$$$$\ $$ |  $$ |$$$$$$$  |$$ |\$$$$$$$ |\$$$$$$$\     //
//    \__|       \______/    \____/ \_______/ \__| \_______|\__|  \__|\______|\__|  \__|\_______/ \__| \_______| \_______|    //
//                                                                                                                            //
//                                                                                                                            //
//                                                                                                                            //
//                                                                                                                            //
//                                                                                                                            //
//                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PDI is ERC721Creator {
    constructor() ERC721Creator("PutDickInside", "PDI") {}
}