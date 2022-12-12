// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Monoleth Memes
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//                                                   //
//                                                   //
//    ___  ___                  _      _   _         //
//    |  \/  |                 | |    | | | |        //
//    | .  . | ___  _ __   ___ | | ___| |_| |__      //
//    | |\/| |/ _ \| '_ \ / _ \| |/ _ \ __| '_ \     //
//    | |  | | (_) | | | | (_) | |  __/ |_| | | |    //
//    \_|  |_/\___/|_| |_|\___/|_|\___|\__|_| |_|    //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract MLM is ERC721Creator {
    constructor() ERC721Creator("Monoleth Memes", "MLM") {}
}