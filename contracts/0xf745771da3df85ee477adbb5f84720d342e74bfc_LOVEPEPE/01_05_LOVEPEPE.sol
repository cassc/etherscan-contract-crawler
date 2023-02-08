// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Spread Lovepepe
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////
//                                                               //
//                                                               //
//                                                               //
//    █    ████▄     ▄   ▄███▄   █ ▄▄  ▄███▄   █ ▄▄  ▄███▄       //
//    █    █   █      █  █▀   ▀  █   █ █▀   ▀  █   █ █▀   ▀      //
//    █    █   █ █     █ ██▄▄    █▀▀▀  ██▄▄    █▀▀▀  ██▄▄        //
//    ███▄ ▀████  █    █ █▄   ▄▀ █     █▄   ▄▀ █     █▄   ▄▀     //
//        ▀        █  █  ▀███▀    █    ▀███▀    █    ▀███▀       //
//                  █▐             ▀             ▀               //
//                  ▐                                            //
//                                                               //
//                                                               //
//                                                               //
///////////////////////////////////////////////////////////////////


contract LOVEPEPE is ERC721Creator {
    constructor() ERC721Creator("Spread Lovepepe", "LOVEPEPE") {}
}