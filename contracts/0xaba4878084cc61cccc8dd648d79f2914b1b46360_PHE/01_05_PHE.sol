// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Punk Hunter Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//    PunkHunter.eth Edition Art      //
//                                    //
//    LOVE THE WORLD AND YOURSELF     //
//                                    //
//    Love PunkHunter.eth             //
//                                    //
//                                    //
////////////////////////////////////////


contract PHE is ERC1155Creator {
    constructor() ERC1155Creator("Punk Hunter Editions", "PHE") {}
}