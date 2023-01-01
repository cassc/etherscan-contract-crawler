// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Everything's Fine
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////
//                          //
//                          //
//                          //
//     _______  _______     //
//    (  ____ \(  ____ \    //
//    | (    \/| (    \/    //
//    | (__    | (__        //
//    |  __)   |  __)       //
//    | (      | (          //
//    | (____/\| )          //
//    (_______/|/           //
//                          //
//                          //
//                          //
//                          //
//////////////////////////////


contract EF is ERC1155Creator {
    constructor() ERC1155Creator("Everything's Fine", "EF") {}
}