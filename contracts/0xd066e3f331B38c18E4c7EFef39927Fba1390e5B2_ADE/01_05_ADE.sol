// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Alex Deer Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//                                                    //
//                                                    //
//     _____  _              ____                     //
//    |  _  || | ___  _ _   |    \  ___  ___  ___     //
//    |     || || -_||_'_|  |  |  || -_|| -_||  _|    //
//    |__|__||_||___||_,_|  |____/ |___||___||_|      //
//                                                    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract ADE is ERC721Creator {
    constructor() ERC721Creator("Alex Deer Editions", "ADE") {}
}