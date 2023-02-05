// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Opepen IRL Edition
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//                                            //
//    .__          __           .__  __       //
//    |__| _____ _/  |_  ____   |__|/  |_     //
//    |  | \__  \\   __\/ __ \  |  \   __\    //
//    |  |  / __ \|  | \  ___/  |  ||  |      //
//    |__| (____  /__|  \___  > |__||__|      //
//              \/          \/                //
//                                            //
//                                            //
//                                            //
////////////////////////////////////////////////


contract OPEPENIRL is ERC721Creator {
    constructor() ERC721Creator("Opepen IRL Edition", "OPEPENIRL") {}
}