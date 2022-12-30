// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Vaughn Meadows Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//    official contract for editions by vaughn meadows    //
//                                                        //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract VME is ERC1155Creator {
    constructor() ERC1155Creator("Vaughn Meadows Editions", "VME") {}
}