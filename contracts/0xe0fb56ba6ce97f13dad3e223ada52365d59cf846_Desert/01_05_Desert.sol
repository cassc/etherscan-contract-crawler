// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Desert inside me
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//                                            //
//     _____                                  //
//    (____ \                        _        //
//     _   \ \ ____  ___  ____  ____| |_      //
//    | |   | / _  )/___)/ _  )/ ___)  _)     //
//    | |__/ ( (/ /|___ ( (/ /| |   | |__     //
//    |_____/ \____|___/ \____)_|    \___)    //
//                                            //
//                                            //
//                                            //
//                                            //
////////////////////////////////////////////////


contract Desert is ERC721Creator {
    constructor() ERC721Creator("Desert inside me", "Desert") {}
}