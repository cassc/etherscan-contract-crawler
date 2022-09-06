// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: We Breathe ft. Lilly
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////
//                                                                                 //
//                                                                                 //
//                   _                 _   _           __ _       _ _ _ _          //
//     __ __ _____  | |__ _ _ ___ __ _| |_| |_  ___   / _| |_    | (_) | |_  _     //
//     \ V  V / -_) | '_ \ '_/ -_) _` |  _| ' \/ -_) |  _|  _|_  | | | | | || |    //
//      \_/\_/\___| |_.__/_| \___\__,_|\__|_||_\___| |_|  \__(_) |_|_|_|_|\_, |    //
//                                                                        |__/     //
//                                                                                 //
//                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////


contract WeBreatheLilly is ERC721Creator {
    constructor() ERC721Creator("We Breathe ft. Lilly", "WeBreatheLilly") {}
}