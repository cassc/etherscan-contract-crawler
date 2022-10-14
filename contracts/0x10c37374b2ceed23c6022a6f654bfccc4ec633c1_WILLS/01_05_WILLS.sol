// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Wills of Fabulae Labs
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//      _______ _           __          ___ _ _         //
//     |__   __| |          \ \        / (_) | |        //
//        | |  | |__   ___   \ \  /\  / / _| | |___     //
//        | |  | '_ \ / _ \   \ \/  \/ / | | | / __|    //
//        | |  | | | |  __/    \  /\  /  | | | \__ \    //
//        |_|  |_| |_|\___|     \/  \/   |_|_|_|___/    //
//                                                      //
//                                                      //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract WILLS is ERC721Creator {
    constructor() ERC721Creator("The Wills of Fabulae Labs", "WILLS") {}
}