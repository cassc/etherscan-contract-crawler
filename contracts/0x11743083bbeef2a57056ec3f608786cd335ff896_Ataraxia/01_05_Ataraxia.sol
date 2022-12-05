// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Project Ataraxia
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//                                                          //
//      __   _____   __    ___    __    _     _    __       //
//     / /\   | |   / /\  | |_)  / /\  \ \_/ | |  / /\      //
//    /_/--\  |_|  /_/--\ |_| \ /_/--\ /_/ \ |_| /_/--\     //
//                                                          //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract Ataraxia is ERC721Creator {
    constructor() ERC721Creator("Project Ataraxia", "Ataraxia") {}
}