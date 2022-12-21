// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sublime
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//                                              //
//                   __    ___                  //
//       _______  __/ /_  / (_)___ ___  ___     //
//      / ___/ / / / __ \/ / / __ `__ \/ _ \    //
//     (__  ) /_/ / /_/ / / / / / / / /  __/    //
//    /____/\__,_/_.___/_/_/_/ /_/ /_/\___/     //
//                                              //
//                                              //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract SUB is ERC721Creator {
    constructor() ERC721Creator("Sublime", "SUB") {}
}