// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Human Nature
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                    //
//                                                                                                    //
//    HH   HH UU   UU MM    MM   AAA   NN   NN    NN   NN   AAA   TTTTTTT UU   UU RRRRRR  EEEEEEE     //
//    HH   HH UU   UU MMM  MMM  AAAAA  NNN  NN    NNN  NN  AAAAA    TTT   UU   UU RR   RR EE          //
//    HHHHHHH UU   UU MM MM MM AA   AA NN N NN    NN N NN AA   AA   TTT   UU   UU RRRRRR  EEEEE       //
//    HH   HH UU   UU MM    MM AAAAAAA NN  NNN    NN  NNN AAAAAAA   TTT   UU   UU RR  RR  EE          //
//    HH   HH  UUUUU  MM    MM AA   AA NN   NN    NN   NN AA   AA   TTT    UUUUU  RR   RR EEEEEEE     //
//                                                                                                    //
//                                                                                                    //
//                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////


contract HUNAT is ERC721Creator {
    constructor() ERC721Creator("Human Nature", "HUNAT") {}
}