// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PONPOP EDITION
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//                                                   //
//                                                   //
//      _____   ____  _   _ _____   ____  _____      //
//     |  __ \ / __ \| \ | |  __ \ / __ \|  __ \     //
//     | |__) | |  | |  \| | |__) | |  | | |__) |    //
//     |  ___/| |  | | . ` |  ___/| |  | |  ___/     //
//     | |    | |__| | |\  | |    | |__| | |         //
//     |_|     \____/|_| \_|_|     \____/|_|         //
//                                                   //
//                                                   //
//                                                   //
//                                                   //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract PONPOP is ERC1155Creator {
    constructor() ERC1155Creator("PONPOP EDITION", "PONPOP") {}
}