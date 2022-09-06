// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bon Voyage.
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//    !                                           //
//    !                                           //
//    !    ____                                   //
//    !   | __ )  ___  _ __                       //
//    !   |  _ \ / _ \| '_ \                      //
//    !   | |_) | (_) | | | |                     //
//    !   |____/ \___/|_| |_|                     //
//    !   \ \   / /__  _   _  __ _  __ _  ___     //
//    !    \ \ / / _ \| | | |/ _` |/ _` |/ _ \    //
//    !     \ V / (_) | |_| | (_| | (_| |  __/    //
//    !      \_/ \___/ \__, |\__,_|\__, |\___|    //
//    !                |___/       |___/          //
//    !                                           //
//    !     An NFT project from VisionArt.AI      //
//    !                                           //
//    !                                           //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract TRAVEL is ERC721Creator {
    constructor() ERC721Creator("Bon Voyage.", "TRAVEL") {}
}