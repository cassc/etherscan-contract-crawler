// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Part time on Christmas Day
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//                                                  //
//     ____  __.     .__ ____  __.                  //
//    |    |/ _|____ |__|    |/ _|____   _____      //
//    |      <_/ __ \|  |      <_/ __ \ /     \     //
//    |    |  \  ___/|  |    |  \  ___/|  Y Y  \    //
//    |____|__ \___  >__|____|__ \___  >__|_|  /    //
//            \/   \/           \/   \/      \/     //
//                                                  //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract PTOCD is ERC721Creator {
    constructor() ERC721Creator("Part time on Christmas Day", "PTOCD") {}
}