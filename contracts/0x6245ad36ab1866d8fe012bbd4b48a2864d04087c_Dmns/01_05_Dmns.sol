// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Portrait of the Demoness
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//    The demoness as fragile and delicate creatures    //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract Dmns is ERC1155Creator {
    constructor() ERC1155Creator("Portrait of the Demoness", "Dmns") {}
}