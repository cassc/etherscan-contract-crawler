// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Yzuz
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//    Bringing My Dreams to Art    //
//                                 //
//                                 //
/////////////////////////////////////


contract Yzuz is ERC1155Creator {
    constructor() ERC1155Creator("Yzuz", "Yzuz") {}
}