// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ADHD by Jack Payne
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//     _______ _______ _______ _______     //
//    |\     /|\     /|\     /|\     /|    //
//    | +---+ | +---+ | +---+ | +---+ |    //
//    | |   | | |   | | |   | | |   | |    //
//    | |A  | | |D  | | |H  | | |D  | |    //
//    | +---+ | +---+ | +---+ | +---+ |    //
//    |/_____\|/_____\|/_____\|/_____\|    //
//                                         //
//                                         //
/////////////////////////////////////////////


contract ADHD is ERC721Creator {
    constructor() ERC721Creator("ADHD by Jack Payne", "ADHD") {}
}