// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Knights Of Illumination Network Symbol
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


contract KOINS is ERC721Creator {
    constructor() ERC721Creator("Knights Of Illumination Network Symbol", "KOINS") {}
}