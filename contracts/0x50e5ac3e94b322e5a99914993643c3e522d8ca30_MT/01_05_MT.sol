// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Milk Tea
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//                                                        //
//     .-.-. .-.-. .-.-. .-.-.      .-.-. .-.-. .-.-.     //
//    ( M .'( i .'( l .'( k .'.-.-.( T .'( e .'( a .'     //
//     `.(   `.(   `.(   `.(  '._.' `.(   `.(   `.(       //
//                                                        //
//                                                        //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract MT is ERC721Creator {
    constructor() ERC721Creator("Milk Tea", "MT") {}
}