// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ARS CIBI FOOD ART
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//                           _ _     _     //
//      __ _ _ __ ___    ___(_) |__ (_)    //
//     / _` | '__/ __|  / __| | '_ \| |    //
//    | (_| | |  \__ \ | (__| | |_) | |    //
//     \__,_|_|  |___/  \___|_|_.__/|_|    //
//                                         //
//                                         //
//                                         //
//                                         //
/////////////////////////////////////////////


contract ACFA1 is ERC1155Creator {
    constructor() ERC1155Creator("ARS CIBI FOOD ART", "ACFA1") {}
}