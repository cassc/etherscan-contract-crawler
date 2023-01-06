// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Project Humans
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////
//                                                             //
//                                                             //
//                                                             //
//    ╦  ╦┬  ┌─┐┌┬┐  ╔╦╗┬─┐┌─┐┌─┐┬ ┬┬  ┌─┐  ╔╦╗┌─┐┌─┐┌─┐┌─┐    //
//    ╚╗╔╝│  ├─┤ ││   ║║├┬┘├─┤│  │ ││  ├─┤   ║ ├┤ ├─┘├┤ └─┐    //
//     ╚╝ ┴─┘┴ ┴─┴┘  ═╩╝┴└─┴ ┴└─┘└─┘┴─┘┴ ┴   ╩ └─┘┴  └─┘└─┘    //
//                                                             //
//                                                             //
//                                                             //
/////////////////////////////////////////////////////////////////


contract VLAD is ERC721Creator {
    constructor() ERC721Creator("Project Humans", "VLAD") {}
}