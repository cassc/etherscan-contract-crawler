// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tales of a Dream
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////
//                                                                               //
//                                                                               //
//                                                                               //
//     ______   _                          ___                                   //
//    (  /     //             /)          ( / \                                  //
//      /__,  // _  (     __ //    __,     /  /_   _  __,  _ _ _                 //
//    _/(_/(_(/_(/_/_)_  (_)//_   (_/(_  (/\_// (_(/_(_/(_/ / / /_               //
//                         /)                                                    //
//                        (/                                                     //
//                                                                               //
//                                                                               //
///////////////////////////////////////////////////////////////////////////////////


contract TLSDM is ERC721Creator {
    constructor() ERC721Creator("Tales of a Dream", "TLSDM") {}
}