// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: abstractions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//    ░█▀█░█▀▄░█▀▀░▀█▀░█▀▄░█▀█░█▀▀░▀█▀░▀█▀░█▀█░█▀█░█▀▀    //
//    ░█▀█░█▀▄░▀▀█░░█░░█▀▄░█▀█░█░░░░█░░░█░░█░█░█░█░▀▀█    //
//    ░▀░▀░▀▀░░▀▀▀░░▀░░▀░▀░▀░▀░▀▀▀░░▀░░▀▀▀░▀▀▀░▀░▀░▀▀▀    //
//                                                        //
//    http://www.chrisrandall.net                         //
//    [email protected]                                 //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract crab is ERC721Creator {
    constructor() ERC721Creator("abstractions", "crab") {}
}