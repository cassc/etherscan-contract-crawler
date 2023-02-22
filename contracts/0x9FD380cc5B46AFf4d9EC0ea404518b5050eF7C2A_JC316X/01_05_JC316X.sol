// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Limited Editions by Jancarlo
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////
//                                                                //
//                                                                //
//         ____.                                 .__              //
//        |    |____    ____   ____ _____ _______|  |   ____      //
//        |    \__  \  /    \_/ ___\\__  \\_  __ \  |  /  _ \     //
//    /\__|    |/ __ \|   |  \  \___ / __ \|  | \/  |_(  <_> )    //
//    \________(____  /___|  /\___  >____  /__|  |____/\____/     //
//                  \/     \/     \/     \/                       //
//                                                                //
//                                                                //
////////////////////////////////////////////////////////////////////


contract JC316X is ERC1155Creator {
    constructor() ERC1155Creator("Limited Editions by Jancarlo", "JC316X") {}
}