// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ipp
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

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


contract IPP is ERC721Creator {
    constructor() ERC721Creator("ipp", "IPP") {}
}