// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TEAM America - ōLand Racing Team
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//                                                 //
//      |  /       _)  |    |       \  | __  /     //
//      ' /    _ \  |  __|  __ \     \ |    /      //
//      . \    __/  |  |    | | |  |\  |   /       //
//     _|\_\ \___| _| \__| _| |_| _| \_| ____|     //
//                                                 //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract RACER is ERC721Creator {
    constructor() ERC721Creator(unicode"TEAM America - ōLand Racing Team", "RACER") {}
}