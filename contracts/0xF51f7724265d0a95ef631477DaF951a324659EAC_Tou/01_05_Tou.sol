// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tourist
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//                                                    //
//      __                      .__          __       //
//    _/  |_  ____  __ _________|__| _______/  |_     //
//    \   __\/  _ \|  |  \_  __ \  |/  ___/\   __\    //
//     |  | (  <_> )  |  /|  | \/  |\___ \  |  |      //
//     |__|  \____/|____/ |__|  |__/____  > |__|      //
//                                      \/            //
//                                                    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract Tou is ERC721Creator {
    constructor() ERC721Creator("Tourist", "Tou") {}
}