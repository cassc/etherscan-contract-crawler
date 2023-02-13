// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ngyyn High Fashion
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//                                          //
//    ______        _     _                 //
//    |  ___|      | |   (_)                //
//    | |_ __ _ ___| |__  _  ___  _ __      //
//    |  _/ _` / __| '_ \| |/ _ \| '_ \     //
//    | || (_| \__ \ | | | | (_) | | | |    //
//    \_| \__,_|___/_| |_|_|\___/|_| |_|    //
//                                          //
//                                          //
//                                          //
//                                          //
//                                          //
//////////////////////////////////////////////


contract METAVERSE is ERC721Creator {
    constructor() ERC721Creator("Ngyyn High Fashion", "METAVERSE") {}
}