// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PhepeRock
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//            888 88e   888'Y88 888     888         //
//     ,"Y88b 888 888b  888 ,'Y 888     888         //
//    "8" 888 888 8888D 888C8   888     888         //
//    ,ee 888 888 888P  888 ",d 888  ,d 888  ,d     //
//    "88 888 888 88"   888,d88 888,d88 888,d88     //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract PHEPE is ERC1155Creator {
    constructor() ERC1155Creator("PhepeRock", "PHEPE") {}
}