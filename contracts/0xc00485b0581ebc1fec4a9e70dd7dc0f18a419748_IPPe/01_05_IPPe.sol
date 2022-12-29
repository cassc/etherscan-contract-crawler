// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ipp edis
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////
//                        //
//                        //
//      _                 //
//     (_)  _     _       //
//      _ _| |_ _| |_     //
//     | |_   _|_   _|    //
//     | | |_|   |_|      //
//     |_|                //
//                        //
//                        //
//                        //
//                        //
////////////////////////////


contract IPPe is ERC1155Creator {
    constructor() ERC1155Creator("ipp edis", "IPPe") {}
}