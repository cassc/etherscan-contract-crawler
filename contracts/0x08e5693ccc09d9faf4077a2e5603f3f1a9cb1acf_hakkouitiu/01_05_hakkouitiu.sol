// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rissyun Daikichi Pass
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////
//                                                                 //
//                                                                 //
//    .__            __    __               .__  __  .__           //
//    |  |__ _____  |  | _|  | ______  __ __|__|/  |_|__|__ __     //
//    |  |  \\__  \ |  |/ /  |/ /  _ \|  |  \  \   __\  |  |  \    //
//    |   Y  \/ __ \|    <|    <  <_> )  |  /  ||  | |  |  |  /    //
//    |___|  (____  /__|_ \__|_ \____/|____/|__||__| |__|____/     //
//         \/     \/     \/    \/                                  //
//                                                                 //
//                                                                 //
/////////////////////////////////////////////////////////////////////


contract hakkouitiu is ERC1155Creator {
    constructor() ERC1155Creator("Rissyun Daikichi Pass", "hakkouitiu") {}
}