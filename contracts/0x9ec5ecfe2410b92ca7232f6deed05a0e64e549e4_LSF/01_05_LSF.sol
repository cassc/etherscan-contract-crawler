// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: A Look is the Strongest Fist
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//                                   //
//     _        _______  _______     //
//    ( \      (  ____ \(  ____ \    //
//    | (      | (    \/| (    \/    //
//    | |      | (_____ | (__        //
//    | |      (_____  )|  __)       //
//    | |            ) || (          //
//    | (____/\/\____) || )          //
//    (_______/\_______)|/           //
//                                   //
//                                   //
//                                   //
//                                   //
///////////////////////////////////////


contract LSF is ERC1155Creator {
    constructor() ERC1155Creator("A Look is the Strongest Fist", "LSF") {}
}