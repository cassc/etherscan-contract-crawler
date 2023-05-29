// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: granneberg 1 of 1's
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//                                   _                      //
//     ___  ___  ___  ___  ___  ___ | |_  ___  ___  ___     //
//    | . ||  _|| .'||   ||   || -_|| . || -_||  _|| . |    //
//    |_  ||_|  |__,||_|_||_|_||___||___||___||_|  |_  |    //
//    |___|                                        |___|    //
//                                                          //
//                         1 of 1's                         //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract CG69 is ERC721Creator {
    constructor() ERC721Creator("granneberg 1 of 1's", "CG69") {}
}