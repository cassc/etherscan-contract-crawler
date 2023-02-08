// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: POTUS 2024
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//      |* * * * * * * * * * OOOOOOOOOOOOOOOOOOOOOOOOO|    //
//      | * * * * * * * * *  OOOOOOOOOOOOOOOOOOOOOOOOO|    //
//      |* * * * * * * * * * OOOOOOOOOOOOOOOOOOOOOOOOO|    //
//      | * * * * * * * * *  OOOOOOOOOOOOOOOOOOOOOOOOO|    //
//      |* * * * * * * * * * OOOOOOOOOOOOOOOOOOOOOOOOO|    //
//      | * * * * * * * * *  OOOOOOOOOOOOOOOOOOOOOOOOO|    //
//      |* * * * * * * * * * OOOOOOOOOOOOOOOOOOOOOOOOO|    //
//      |OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO|    //
//      |OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO|    //
//      |OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO|    //
//      |OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO|    //
//      |OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO|    //
//      |OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO|    //
//                                                        //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract POTUS2024 is ERC1155Creator {
    constructor() ERC1155Creator("POTUS 2024", "POTUS2024") {}
}