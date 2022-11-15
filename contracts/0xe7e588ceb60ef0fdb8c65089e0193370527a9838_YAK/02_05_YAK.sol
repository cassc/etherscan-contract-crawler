// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Yakadashi
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//    ([Y_O_M_U])([Y_O_M_U])([Y_O_M_U])([Y_O_M_U])    //
//    ([Y_O_M_U])([Y_O_M_U])([Y_O_M_U])([Y_O_M_U])    //
//    ([Y_O_M_U])([Y_O_M_U])([Y_O_M_U])([Y_O_M_U])    //
//    ([Y_O_M_U])([Y_O_M_U])([Y_O_M_U])([Y_O_M_U])    //
//    ([Y_O_M_U])([Y_O_M_U])([Y_O_M_U])([Y_O_M_U])    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract YAK is ERC721Creator {
    constructor() ERC721Creator("Yakadashi", "YAK") {}
}