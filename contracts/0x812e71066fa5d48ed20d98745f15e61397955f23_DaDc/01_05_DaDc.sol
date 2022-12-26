// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Data Clouds
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//    ░█▀▄▒▄▀▄░▀█▀▒▄▀▄░░░▄▀▀░█▒░░▄▀▄░█▒█░█▀▄░▄▀▀    //
//    ▒█▄▀░█▀█░▒█▒░█▀█▒░░▀▄▄▒█▄▄░▀▄▀░▀▄█▒█▄▀▒▄██    //
//                                                  //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract DaDc is ERC1155Creator {
    constructor() ERC1155Creator("Data Clouds", "DaDc") {}
}