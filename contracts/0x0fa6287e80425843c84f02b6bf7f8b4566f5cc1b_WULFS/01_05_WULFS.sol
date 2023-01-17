// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: wulfs
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//                                  //
//                    _  __         //
//                   | |/ _|        //
//    __      ___   _| | |_ ___     //
//    \ \ /\ / / | | | |  _/ __|    //
//     \ V  V /| |_| | | | \__ \    //
//      \_/\_/  \__,_|_|_| |___/    //
//                                  //
//                                  //
//                                  //
//                                  //
//                                  //
//////////////////////////////////////


contract WULFS is ERC1155Creator {
    constructor() ERC1155Creator("wulfs", "WULFS") {}
}