// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BOK-Collection
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//                                      //
//    <-.(`-')            <-.(`-')      //
//     __( OO)      .->    __( OO)      //
//    '-'---.\ (`-')----. '-'. ,--.     //
//    | .-. (/ ( OO).-.  '|  .'   /     //
//    | '-' `.)( _) | |  ||      /)     //
//    | /`'.  | \|  |)|  ||  .   '      //
//    | '--'  /  '  '-'  '|  |\   \     //
//    `------'    `-----' `--' '--'     //
//                                      //
//                                      //
//                                      //
//////////////////////////////////////////


contract BOKC is ERC1155Creator {
    constructor() ERC1155Creator("BOK-Collection", "BOKC") {}
}