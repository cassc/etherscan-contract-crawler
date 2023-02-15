// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: twemoji
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//                                                       //
//     _                                        _  _     //
//    | |_ __      __  ___  _ __ ___    ___    (_)(_)    //
//    | __|\ \ /\ / / / _ \| '_ ` _ \  / _ \   | || |    //
//    | |_  \ V  V / |  __/| | | | | || (_) |  | || |    //
//     \__|  \_/\_/   \___||_| |_| |_| \___/  _/ ||_|    //
//                                           |__/        //
//                                                       //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract twemoji is ERC721Creator {
    constructor() ERC721Creator("twemoji", "twemoji") {}
}