// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Life is a Splatter
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    My name is Inaaya Peerani. I am an young aspiring artist trying to enter and learn more about NFTs.     //
//                                                                                                            //
//    This is my first project. There’s no utility, no roadmap or no future drops guaranteed as of now.       //
//                                                                                                            //
//    I hope you like my art and thank you for your support in advance.                                       //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LiS is ERC721Creator {
    constructor() ERC721Creator("Life is a Splatter", "LiS") {}
}