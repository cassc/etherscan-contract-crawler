// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Thirst
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//                                    //
//     _____ _     _          _       //
//    |_   _| |   (_)        | |      //
//      | | | |__  _ _ __ ___| |_     //
//      | | | '_ \| | '__/ __| __|    //
//      | | | | | | | |  \__ \ |_     //
//      \_/ |_| |_|_|_|  |___/\__|    //
//                                    //
//                                    //
////////////////////////////////////////


contract THIRST is ERC721Creator {
    constructor() ERC721Creator("Thirst", "THIRST") {}
}