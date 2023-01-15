// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MUKHLIS's Art Journey oe
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//       _____ __________  _________              __       //
//      /  _  \\______   \/   _____/____ ________/  |_     //
//     /  /_\  \|    |  _/\_____  \\__  \\_  __ \   __\    //
//    /    |    \    |   \/        \/ __ \|  | \/|  |      //
//    \____|__  /______  /_______  (____  /__|   |__|      //
//            \/       \/        \/     \/                 //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract ABSartOE is ERC1155Creator {
    constructor() ERC1155Creator("MUKHLIS's Art Journey oe", "ABSartOE") {}
}