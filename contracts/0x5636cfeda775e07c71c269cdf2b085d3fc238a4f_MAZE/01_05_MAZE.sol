// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: THE MAZE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                         //
//                                                                                                                                                                         //
//    Are you brave enough to unravel the secrets hidden within the winding paths of the maze? Something mysterious awaits those who dare to venture to the other side.    //
//                                                                                                                                                                         //
//                                                                                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MAZE is ERC1155Creator {
    constructor() ERC1155Creator("THE MAZE", "MAZE") {}
}