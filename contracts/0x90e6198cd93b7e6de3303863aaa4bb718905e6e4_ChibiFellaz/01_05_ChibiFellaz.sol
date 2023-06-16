// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Chibi Fellaz
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

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


contract ChibiFellaz is ERC1155Creator {
    constructor() ERC1155Creator("Chibi Fellaz", "ChibiFellaz") {}
}