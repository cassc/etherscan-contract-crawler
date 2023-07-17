// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lost Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//                                  //
//    .__                  __       //
//    |  |   ____  _______/  |_     //
//    |  |  /  _ \/  ___/\   __\    //
//    |  |_(  <_> )___ \  |  |      //
//    |____/\____/____  > |__|      //
//                    \/            //
//                                  //
//                                  //
//                                  //
//////////////////////////////////////


contract LOST is ERC1155Creator {
    constructor() ERC1155Creator("Lost Editions", "LOST") {}
}