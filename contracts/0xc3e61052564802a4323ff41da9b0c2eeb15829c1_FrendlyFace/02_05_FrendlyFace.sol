// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Friendly Faces
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//                                                           //
//    ,--.   ,--.        ,----.                              //
//    |  |   `--',-----.'  .-./    ,---.  ,--,--.,--.--.     //
//    |  |   ,--.`-.  / |  | .---.| .-. :' ,-.  ||  .--'     //
//    |  '--.|  | /  `-.'  '--'  |\   --.\ '-'  ||  |        //
//    `-----'`--'`-----' `------'  `----' `--`--'`--'        //
//                                                           //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract FrendlyFace is ERC721Creator {
    constructor() ERC721Creator("Friendly Faces", "FrendlyFace") {}
}