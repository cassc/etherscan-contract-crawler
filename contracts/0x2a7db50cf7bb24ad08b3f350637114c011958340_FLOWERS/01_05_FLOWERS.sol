// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sudden Flowers by Eric Gottesman
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//    SUDDEN FLOWERS BY ERIC GOTTESMAN        //
//    IN COLLABORATION WITH SUDDEN FLOWERS    //
//    IMAGES © ERIC GOTTESMAN                 //
//    ALL RIGHTS RESERVED                     //
//                                            //
//                                            //
////////////////////////////////////////////////


contract FLOWERS is ERC721Creator {
    constructor() ERC721Creator("Sudden Flowers by Eric Gottesman", "FLOWERS") {}
}