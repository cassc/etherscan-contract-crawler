// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 0xunix.eth
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//       __                _           _   _        //
//      /  \__ ___  _ _ _ (_)_ __  ___| |_| |_      //
//     | () \ \ / || | ' \| \ \ /_/ -_)  _| ' \     //
//      \__//_\_\\_,_|_||_|_/_\_(_)___|\__|_||_|    //
//                                                  //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract unixx is ERC1155Creator {
    constructor() ERC1155Creator("0xunix.eth", "unixx") {}
}