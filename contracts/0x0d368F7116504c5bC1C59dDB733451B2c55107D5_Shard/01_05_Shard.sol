// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Shard Swamp Pass
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


contract Shard is ERC721Creator {
    constructor() ERC721Creator("Shard Swamp Pass", "Shard") {}
}