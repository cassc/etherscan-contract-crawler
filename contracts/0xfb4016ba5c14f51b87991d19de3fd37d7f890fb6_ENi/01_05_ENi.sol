// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: iAMENi
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//                                              //
//      _     _     __  __  _____  _   _  _     //
//     (_)   / \   |  \/  || ____|| \ | |(_)    //
//     | |  / _ \  | |\/| ||  _|  |  \| || |    //
//     | | / ___ \ | |  | || |___ | |\  || |    //
//     |_|/_/   \_\|_|  |_||_____||_| \_||_|    //
//                                              //
//                                              //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract ENi is ERC1155Creator {
    constructor() ERC1155Creator("iAMENi", "ENi") {}
}