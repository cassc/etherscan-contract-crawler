// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: tinarfz
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//    _____  _  _      ____  ____  _____ ____      //
//    /__ __\/ \/ \  /|/  _ \/  __\/    //_   \    //
//      / \  | || |\ ||| / \||  \/||  __\ /   /    //
//      | |  | || | \||| |-|||    /| |   /   /_    //
//      \_/  \_/\_/  \|\_/ \|\_/\_\\_/   \____/    //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract tinarfz is ERC721Creator {
    constructor() ERC721Creator("tinarfz", "tinarfz") {}
}