// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: For YAKO Holders
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                              //
//                                                                                              //
//                                                                                              //
//    8888               Yb  dP    db    8  dP .d88b.    8   8       8    8                     //
//    8www .d8b. 8d8b     YbdP    dPYb   8wdP  8P  Y8    8www8 .d8b. 8 .d88 .d88b 8d8b d88b     //
//    8    8' .8 8P        YP    dPwwYb  88Yb  8b  d8    8   8 8' .8 8 8  8 8.dP' 8P   `Yb.     //
//    8    `Y8P' 8         88   dP    Yb 8  Yb `Y88P'    8   8 `Y8P' 8 `Y88 `Y88P 8    Y88P     //
//                                                                                              //
//                                                                                              //
//                                                                                              //
//                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////


contract FYH is ERC721Creator {
    constructor() ERC721Creator("For YAKO Holders", "FYH") {}
}