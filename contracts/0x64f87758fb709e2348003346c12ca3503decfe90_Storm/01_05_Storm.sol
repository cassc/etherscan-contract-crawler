// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Weather
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//                                              //
//      _________ __                            //
//     /   _____//  |_  ___________  _____      //
//     \_____  \\   __\/  _ \_  __ \/     \     //
//     /        \|  | (  <_> )  | \/  Y Y  \    //
//    /_______  /|__|  \____/|__|  |__|_|  /    //
//            \/                         \/     //
//                                              //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract Storm is ERC721Creator {
    constructor() ERC721Creator("Weather", "Storm") {}
}