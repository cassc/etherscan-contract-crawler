// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Singing and Forgetting
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//                              //
//          _                   //
//      ___| |_  ___  ____      //
//     /___)  _)/ _ \|  _ \     //
//    |___ | |_| |_| | | | |    //
//    (___/ \___)___/| ||_/     //
//                   |_|        //
//                              //
//                              //
//////////////////////////////////


contract BRDR is ERC721Creator {
    constructor() ERC721Creator("Singing and Forgetting", "BRDR") {}
}