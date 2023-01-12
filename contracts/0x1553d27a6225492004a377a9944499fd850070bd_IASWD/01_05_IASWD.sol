// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: It all started with a Drawing
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////
//                                                                //
//                                                                //
//    ___  __  __    __    __       _____  __  _____  _           //
//       /   \/__\/ _\  /__\/\ \ \/\  /\\_   \/ _\/__   \/_\      //
//      / /\ /_\  \ \  /_\ /  \/ / /_/ / / /\/\ \   / /\//_\\     //
//     / /_///__  _\ \//__/ /\  / __  /\/ /_  _\ \ / / /  _  \    //
//    /___,'\__/  \__/\__/\_\ \/\/ /_/\____/  \__/ \/  \_/ \_/    //
//                                                                //
//                                                                //
////////////////////////////////////////////////////////////////////


contract IASWD is ERC1155Creator {
    constructor() ERC1155Creator("It all started with a Drawing", "IASWD") {}
}