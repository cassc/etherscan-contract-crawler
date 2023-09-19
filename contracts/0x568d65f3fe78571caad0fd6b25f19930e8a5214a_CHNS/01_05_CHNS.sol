// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Chones
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//                                                    //
//                                                    //
//    ▄█▄     ▄  █ ████▄    ▄   ▄███▄     ▄▄▄▄▄       //
//    █▀ ▀▄  █   █ █   █     █  █▀   ▀   █     ▀▄     //
//    █   ▀  ██▀▀█ █   █ ██   █ ██▄▄   ▄  ▀▀▀▀▄       //
//    █▄  ▄▀ █   █ ▀████ █ █  █ █▄   ▄▀ ▀▄▄▄▄▀        //
//    ▀███▀     █        █  █ █ ▀███▀                 //
//             ▀         █   ██                       //
//                                                    //
//                                                    //
//                                                    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract CHNS is ERC721Creator {
    constructor() ERC721Creator("Chones", "CHNS") {}
}