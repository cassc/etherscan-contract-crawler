// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: In Silence
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//                                                      //
//        ____         _____ _ __                       //
//       /  _/___     / ___/(_) /__  ____  ________     //
//       / // __ \    \__ \/ / / _ \/ __ \/ ___/ _ \    //
//     _/ // / / /   ___/ / / /  __/ / / / /__/  __/    //
//    /___/_/ /_/   /____/_/_/\___/_/ /_/\___/\___/     //
//                                                      //
//                                                      //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract Silence is ERC1155Creator {
    constructor() ERC1155Creator("In Silence", "Silence") {}
}