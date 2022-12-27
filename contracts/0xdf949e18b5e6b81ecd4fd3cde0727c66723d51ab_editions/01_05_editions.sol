// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: editions by drabstract
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//         _           _         _                  _       //
//        | |         | |       | |                | |      //
//      __| |_ __ __ _| |__  ___| |_ _ __ __ _  ___| |_     //
//     / _` | '__/ _` | '_ \/ __| __| '__/ _` |/ __| __|    //
//    | (_| | | | (_| | |_) \__ \ |_| | | (_| | (__| |_     //
//     \__,_|_|  \__,_|_.__/|___/\__|_|  \__,_|\___|\__|    //
//                                                          //
//                                                          //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract editions is ERC1155Creator {
    constructor() ERC1155Creator("editions by drabstract", "editions") {}
}