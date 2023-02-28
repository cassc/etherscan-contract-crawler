// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MiniMjm
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//                                              //
//      __  __ _       _ __  __ _               //
//     |  \/  (_)     (_)  \/  (_)              //
//     | \  / |_ _ __  _| \  / |_ _ __ ___      //
//     | |\/| | | '_ \| | |\/| | | '_ ` _ \     //
//     | |  | | | | | | | |  | | | | | | | |    //
//     |_|  |_|_|_| |_|_|_|  |_| |_| |_| |_|    //
//                            _/ |              //
//                           |__/               //
//                                              //
//                                              //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract MNJ is ERC1155Creator {
    constructor() ERC1155Creator("MiniMjm", "MNJ") {}
}