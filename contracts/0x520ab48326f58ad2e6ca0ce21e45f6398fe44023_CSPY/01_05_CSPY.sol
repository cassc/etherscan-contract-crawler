// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Chinese Spy Balloon
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////
//                                                                                  //
//                                                                                  //
//    Commemorating the shooting down of the Chinese Spy Balloon over the U.S.A     //
//                                                                                  //
//                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////


contract CSPY is ERC1155Creator {
    constructor() ERC1155Creator("Chinese Spy Balloon", "CSPY") {}
}