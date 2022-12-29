// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nixa
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//                                  //
//     _   _ _______   __  ___      //
//    | \ | |_   _\ \ / / / _ \     //
//    |  \| | | |  \ V / / /_\ \    //
//    | . ` | | |  /   \ |  _  |    //
//    | |\  |_| |_/ /^\ \| | | |    //
//    \_| \_/\___/\/   \/\_| |_/    //
//                                  //
//                                  //
//                                  //
//                                  //
//                                  //
//////////////////////////////////////


contract Nixa is ERC1155Creator {
    constructor() ERC1155Creator("Nixa", "Nixa") {}
}