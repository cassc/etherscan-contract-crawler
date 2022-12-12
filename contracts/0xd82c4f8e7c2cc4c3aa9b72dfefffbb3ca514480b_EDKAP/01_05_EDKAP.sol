// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Editions by Keith Allen Phillips
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////
//                                                               //
//                                                               //
//                                                               //
//     ________  ______   ___  ____        _       _______       //
//    |_   __  ||_   _ `.|_  ||_  _|      / \     |_   __ \      //
//      | |_ \_|  | | `. \ | |_/ /       / _ \      | |__) |     //
//      |  _| _   | |  | | |  __'.      / ___ \     |  ___/      //
//     _| |__/ | _| |_.' /_| |  \ \_  _/ /   \ \_  _| |_         //
//    |________||______.'|____||____||____| |____||_____|        //
//                                                               //
//                                                               //
//                                                               //
//                                                               //
///////////////////////////////////////////////////////////////////


contract EDKAP is ERC1155Creator {
    constructor() ERC1155Creator("Editions by Keith Allen Phillips", "EDKAP") {}
}