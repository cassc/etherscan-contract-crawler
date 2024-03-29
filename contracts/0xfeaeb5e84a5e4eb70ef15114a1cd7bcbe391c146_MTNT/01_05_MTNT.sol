// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mutant Ancestors
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                              //
//                                                                                              //
//      __    __   __    __    _______    _____    __   __   _______                            //
//     /_/\  /\_\ /\_\  /_/\ /\_______)\ /\___/\  /_/\ /\_\/\_______)\                          //
//     ) ) \/ ( (( ( (  ) ) )\(___  __\// / _ \ \ ) ) \ ( (\(___  __\/                          //
//    /_/ \  / \_\\ \ \/ / /   / / /    \ \(_)/ //_/   \ \_\ / / /                              //
//    \ \ \\// / / \ \  / /   ( ( (     / / _ \ \\ \ \   / /( ( (                               //
//     )_) )( (_(  ( (__) )    \ \ \   ( (_( )_) ))_) \ (_(  \ \ \                              //
//     \_\/  \/_/   \/__\/     /_/_/    \/_/ \_\/ \_\/ \/_/  /_/_/                              //
//       _____    __   __    _____    _____  ______   _______    _____     __ __    ______      //
//      /\___/\  /_/\ /\_\  /\ __/\ /\_____\/ ____/\/\_______)\ ) ___ (   /_/\__/\ / ____/\     //
//     / / _ \ \ ) ) \ ( (  ) )__\/( (_____/) ) __\/\(___  __\// /\_/\ \  ) ) ) ) )) ) __\/     //
//     \ \(_)/ //_/   \ \_\/ / /    \ \__\   \ \ \    / / /   / /_/ (_\ \/_/ /_/_/  \ \ \       //
//     / / _ \ \\ \ \   / /\ \ \_   / /__/_  _\ \ \  ( ( (    \ \ )_/ / /\ \ \ \ \  _\ \ \      //
//    ( (_( )_) ))_) \ (_(  ) )__/\( (_____\)____) )  \ \ \    \ \/_\/ /  )_) ) \ \)____)       //
//                                                                                              //
//                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////


contract MTNT is ERC721Creator {
    constructor() ERC721Creator("Mutant Ancestors", "MTNT") {}
}