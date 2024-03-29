// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MONO [G]
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                    //
//                                                                                                    //
//    |||||       |||||  |||||||||||||  ||||||     |||||  |||||||||||||  |||||    ||||||||   |||||    //
//    |||||||   |||||||  |||||   |||||  ||||||||   |||||  |||||   |||||  |||   |||||           |||    //
//    ||||| ||||| |||||  |||||   |||||  ||||| |||  |||||  |||||   |||||  |||  |||||   |||||||  |||    //
//    |||||  |||  |||||  |||||   |||||  |||||  ||| |||||  |||||   |||||  |||   ||||     ||||   |||    //
//    |||||       |||||  |||||   |||||  |||||   ||||||||  |||||   |||||  |||    |||||   ||||   |||    //
//    |||||       |||||  |||||||||||||  |||||     ||||||  |||||||||||||  |||||   ||||||||||  |||||    //
//                                                                                                    //
//    |||||       |||||  |||||||||||||  ||||||     |||||  |||||||||||||  |||||    ||||||||   |||||    //
//    |||||||   |||||||  |||||   |||||  ||||||||   |||||  |||||   |||||  |||   |||||           |||    //
//    ||||| ||||| |||||  |||||   |||||  ||||| |||  |||||  |||||   |||||  |||  |||||   |||||||  |||    //
//    |||||  |||  |||||  |||||   |||||  |||||  ||| |||||  |||||   |||||  |||   ||||     ||||   |||    //
//    |||||       |||||  |||||   |||||  |||||   ||||||||  |||||   |||||  |||    |||||   ||||   |||    //
//    |||||       |||||  |||||||||||||  |||||     ||||||  |||||||||||||  |||||   ||||||||||  |||||    //
//                                                                                                    //
//    |||||       |||||  |||||||||||||  ||||||     |||||  |||||||||||||  |||||    ||||||||   |||||    //
//    |||||||   |||||||  |||||   |||||  ||||||||   |||||  |||||   |||||  |||   |||||           |||    //
//    ||||| ||||| |||||  |||||   |||||  ||||| |||  |||||  |||||   |||||  |||  |||||   |||||||  |||    //
//    |||||  |||  |||||  |||||   |||||  |||||  ||| |||||  |||||   |||||  |||   ||||     ||||   |||    //
//    |||||       |||||  |||||   |||||  |||||   ||||||||  |||||   |||||  |||    |||||   ||||   |||    //
//    |||||       |||||  |||||||||||||  |||||     ||||||  |||||||||||||  |||||   ||||||||||  |||||    //
//                                                                                                    //
//    |||||       |||||  |||||||||||||  ||||||     |||||  |||||||||||||  |||||    ||||||||   |||||    //
//    |||||||   |||||||  |||||   |||||  ||||||||   |||||  |||||   |||||  |||   |||||           |||    //
//    ||||| ||||| |||||  |||||   |||||  ||||| |||  |||||  |||||   |||||  |||  |||||   |||||||  |||    //
//    |||||  |||  |||||  |||||   |||||  |||||  ||| |||||  |||||   |||||  |||   ||||     ||||   |||    //
//    |||||       |||||  |||||   |||||  |||||   ||||||||  |||||   |||||  |||    |||||   ||||   |||    //
//    |||||       |||||  |||||||||||||  |||||     ||||||  |||||||||||||  |||||   ||||||||||  |||||    //
//                                                                                                    //
//    |||||       |||||  |||||||||||||  ||||||     |||||  |||||||||||||  |||||    ||||||||   |||||    //
//    |||||||   |||||||  |||||   |||||  ||||||||   |||||  |||||   |||||  |||   |||||           |||    //
//    ||||| ||||| |||||  |||||   |||||  ||||| |||  |||||  |||||   |||||  |||  |||||   |||||||  |||    //
//    |||||  |||  |||||  |||||   |||||  |||||  ||| |||||  |||||   |||||  |||   ||||     ||||   |||    //
//    |||||       |||||  |||||   |||||  |||||   ||||||||  |||||   |||||  |||    |||||   ||||   |||    //
//    |||||       |||||  |||||||||||||  |||||     ||||||  |||||||||||||  |||||   ||||||||||  |||||    //
//                                                                                                    //
//    |||||       |||||  |||||||||||||  ||||||     |||||  |||||||||||||  |||||    ||||||||   |||||    //
//    |||||||   |||||||  |||||   |||||  ||||||||   |||||  |||||   |||||  |||   |||||           |||    //
//    ||||| ||||| |||||  |||||   |||||  ||||| |||  |||||  |||||   |||||  |||  |||||   |||||||  |||    //
//    |||||  |||  |||||  |||||   |||||  |||||  ||| |||||  |||||   |||||  |||   ||||     ||||   |||    //
//    |||||       |||||  |||||   |||||  |||||   ||||||||  |||||   |||||  |||    |||||   ||||   |||    //
//    |||||       |||||  |||||||||||||  |||||     ||||||  |||||||||||||  |||||   ||||||||||  |||||    //
//                                                                                                    //
//    |||||       |||||  |||||||||||||  ||||||     |||||  |||||||||||||  |||||    ||||||||   |||||    //
//    |||||||   |||||||  |||||   |||||  ||||||||   |||||  |||||   |||||  |||   |||||           |||    //
//    ||||| ||||| |||||  |||||   |||||  ||||| |||  |||||  |||||   |||||  |||  |||||   |||||||  |||    //
//    |||||  |||  |||||  |||||   |||||  |||||  ||| |||||  |||||   |||||  |||   ||||     ||||   |||    //
//    |||||       |||||  |||||   |||||  |||||   ||||||||  |||||   |||||  |||    |||||   ||||   |||    //
//    |||||       |||||  |||||||||||||  |||||     ||||||  |||||||||||||  |||||   ||||||||||  |||||    //
//                                                                                                    //
//    |||||       |||||  |||||||||||||  ||||||     |||||  |||||||||||||  |||||    ||||||||   |||||    //
//    |||||||   |||||||  |||||   |||||  ||||||||   |||||  |||||   |||||  |||   |||||           |||    //
//    ||||| ||||| |||||  |||||   |||||  ||||| |||  |||||  |||||   |||||  |||  |||||   |||||||  |||    //
//    |||||  |||  |||||  |||||   |||||  |||||  ||| |||||  |||||   |||||  |||   ||||     ||||   |||    //
//    |||||       |||||  |||||   |||||  |||||   ||||||||  |||||   |||||  |||    |||||   ||||   |||    //
//    |||||       |||||  |||||||||||||  |||||     ||||||  |||||||||||||  |||||   ||||||||||  |||||    //
//                                                                                                    //
//    |||||       |||||  |||||||||||||  ||||||     |||||  |||||||||||||  |||||    ||||||||   |||||    //
//    |||||||   |||||||  |||||   |||||  ||||||||   |||||  |||||   |||||  |||   |||||           |||    //
//    ||||| ||||| |||||  |||||   |||||  ||||| |||  |||||  |||||   |||||  |||  |||||   |||||||  |||    //
//    |||||  |||  |||||  |||||   |||||  |||||  ||| |||||  |||||   |||||  |||   ||||     ||||   |||    //
//    |||||       |||||  |||||   |||||  |||||   ||||||||  |||||   |||||  |||    |||||   ||||   |||    //
//    |||||       |||||  |||||||||||||  |||||     ||||||  |||||||||||||  |||||   ||||||||||  |||||    //
//                                                                                                    //
//    |||||       |||||  |||||||||||||  ||||||     |||||  |||||||||||||  |||||    ||||||||   |||||    //
//    |||||||   |||||||  |||||   |||||  ||||||||   |||||  |||||   |||||  |||   |||||           |||    //
//    ||||| ||||| |||||  |||||   |||||  ||||| |||  |||||  |||||   |||||  |||  |||||   |||||||  |||    //
//    |||||  |||  |||||  |||||   |||||  |||||  ||| |||||  |||||   |||||  |||   ||||     ||||   |||    //
//    |||||       |||||  |||||   |||||  |||||   ||||||||  |||||   |||||  |||    |||||   ||||   |||    //
//    |||||       |||||  |||||||||||||  |||||     ||||||  |||||||||||||  |||||   ||||||||||  |||||    //
//                                                                                                    //
//    |||||       |||||  |||||||||||||  ||||||     |||||  |||||||||||||  |||||    ||||||||   |||||    //
//    |||||||   |||||||  |||||   |||||  ||||||||   |||||  |||||   |||||  |||   |||||           |||    //
//    ||||| ||||| |||||  |||||   |||||  ||||| |||  |||||  |||||   |||||  |||  |||||   |||||||  |||    //
//    |||||  |||  |||||  |||||   |||||  |||||  ||| |||||  |||||   |||||  |||   ||||     ||||   |||    //
//    |||||       |||||  |||||   |||||  |||||   ||||||||  |||||   |||||  |||    |||||   ||||   |||    //
//    |||||       |||||  |||||||||||||  |||||     ||||||  |||||||||||||  |||||   ||||||||||  |||||    //
//                                                                                                    //
//                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MNG is ERC721Creator {
    constructor() ERC721Creator("MONO [G]", "MNG") {}
}