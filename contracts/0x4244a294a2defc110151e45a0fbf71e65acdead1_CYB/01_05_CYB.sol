// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Create Your Bear
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                //
//                                                                                                                                                //
//    Holding a Bear allows you to customize its appearance through a series of burn stages where you choose the attributes you want on chain!    //
//                                                                                                                                                //
//                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CYB is ERC1155Creator {
    constructor() ERC1155Creator("Create Your Bear", "CYB") {}
}