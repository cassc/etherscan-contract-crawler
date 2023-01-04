// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RoSW Privilege Collection
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//                                                      //
//    __________        ___________      __             //
//    \______   \ ____ /   _____/  \    /  \______      //
//     |       _//  _ \\_____  \\   \/\/   /\____ \     //
//     |    |   (  <_> )        \\        / |  |_> >    //
//     |____|_  /\____/_______  / \__/\  /  |   __/     //
//            \/              \/       \/   |__|        //
//                                                      //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract RoSWp is ERC1155Creator {
    constructor() ERC1155Creator("RoSW Privilege Collection", "RoSWp") {}
}