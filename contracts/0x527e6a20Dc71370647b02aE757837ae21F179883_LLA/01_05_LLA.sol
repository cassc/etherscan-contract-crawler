// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Little Lis Art
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//     _     _ _   _   _        _     _         //
//    | |   (_) | | | | |      | |   (_)        //
//    | |    _| |_| |_| | ___  | |    _ ___     //
//    | |   | | __| __| |/ _ \ | |   | / __|    //
//    | |___| | |_| |_| |  __/ | |___| \__ \    //
//    \_____/_|\__|\__|_|\___| \_____/_|___/    //
//                                              //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract LLA is ERC1155Creator {
    constructor() ERC1155Creator("Little Lis Art", "LLA") {}
}