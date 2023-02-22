// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Ethereal Dance
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////
//                                                                                  //
//                                                                                  //
//                                                                                  //
//     ________         ______  __                    __  ___                       //
//    /_  __/ /  ___   / __/ /_/ /  ___ _______ ___ _/ / / _ \___ ____  _______     //
//     / / / _ \/ -_) / _// __/ _ \/ -_) __/ -_) _ `/ / / // / _ `/ _ \/ __/ -_)    //
//    /_/ /_//_/\__/ /___/\__/_//_/\__/_/  \__/\_,_/_/ /____/\_,_/_//_/\__/\__/     //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//    The Ethereal Dance                                                            //
//                                                                                  //
//    celebrates a feminine energy that is free flowing                             //
//    and not bound by rules                                                        //
//                                                                                  //
//    created by Alyse Gamson                                                       //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////


contract Alyse is ERC721Creator {
    constructor() ERC721Creator("The Ethereal Dance", "Alyse") {}
}