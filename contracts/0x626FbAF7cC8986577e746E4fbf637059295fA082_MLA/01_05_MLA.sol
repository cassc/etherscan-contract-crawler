// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mason London's Americana
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//      * * * * * * * * * * MASON-LONDONS-AMERICANA-MAS    //
//       * * * * * * * * *  :::::::::::::::::::::::::::    //
//      * * * * * * * * * * MASON-LONDONS-AMERICANA-MAS    //
//       * * * * * * * * *  :::::::::::::::::::::::::::    //
//      * * * * * * * * * * MASON-LONDONS-AMERICANA-MAS    //
//       * * * * * * * * *  :::::::::::::::::::::::::::    //
//      * * * * * * * * * * MASON-LONDONS-AMERICANA-MAS    //
//      :::::::::::::::::::::::::::::::::::::::::::::::    //
//      MASON-LONDONS-AMERICANA-MASON-LONDONS-AMERICANA    //
//      :::::::::::::::::::::::::::::::::::::::::::::::    //
//      MASON-LONDONS-AMERICANA-MASON-LONDONS-AMERICANA    //
//      :::::::::::::::::::::::::::::::::::::::::::::::    //
//      MASON-LONDONS-AMERICANA-MASON-LONDONS-AMERICANA    //
//      :::::::::::::::::::::::::::::::::::::::::::::::    //
//      MASON-LONDONS-AMERICANA-MASON-LONDONS-AMERICANA    //
//                                                         //
//                                                         //
//                                                         //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract MLA is ERC1155Creator {
    constructor() ERC1155Creator("Mason London's Americana", "MLA") {}
}