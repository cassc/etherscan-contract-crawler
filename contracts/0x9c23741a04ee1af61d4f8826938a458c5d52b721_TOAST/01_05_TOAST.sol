// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Shadows of Toast
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//    ,--------. ,-----.   ,---.   ,---. ,--------.     //
//    '--.  .--''  .-.  ' /  O  \ '   .-''--.  .--'     //
//       |  |   |  | |  ||  .-.  |`.  `-.   |  |        //
//       |  |   '  '-'  '|  | |  |.-'    |  |  |        //
//       `--'    `-----' `--' `--'`-----'   `--'        //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract TOAST is ERC1155Creator {
    constructor() ERC1155Creator("Shadows of Toast", "TOAST") {}
}