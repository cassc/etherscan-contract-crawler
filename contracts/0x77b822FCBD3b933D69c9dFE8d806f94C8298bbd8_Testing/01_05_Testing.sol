// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Testing
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//    ___________              __       //
//    \__    ___/___   _______/  |_     //
//      |    |_/ __ \ /  ___/\   __\    //
//      |    |\  ___/ \___ \  |  |      //
//      |____| \___  >____  > |__|      //
//                 \/     \/            //
//                                      //
//                                      //
//////////////////////////////////////////


contract Testing is ERC1155Creator {
    constructor() ERC1155Creator("Testing", "Testing") {}
}