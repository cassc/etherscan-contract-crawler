// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Anima Renders
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//                                                    //
//      ,---.  ,--.  ,--.,--.,--.   ,--.  ,---.       //
//     /  O  \ |  ,'.|  ||  ||   `.'   | /  O  \      //
//    |  .-.  ||  |' '  ||  ||  |'.'|  ||  .-.  |     //
//    |  | |  ||  | `   ||  ||  |   |  ||  | |  |     //
//    `--' `--'`--'  `--'`--'`--'   `--'`--' `--'     //
//                                                    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract AR is ERC721Creator {
    constructor() ERC721Creator("Anima Renders", "AR") {}
}