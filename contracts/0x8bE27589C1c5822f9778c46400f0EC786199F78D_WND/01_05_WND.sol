// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Wanderer
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    ╦ ╦┌─┐┌┐┌┌┬┐┌─┐┬─┐┌─┐┬─┐    //
//    ║║║├─┤│││ ││├┤ ├┬┘├┤ ├┬┘    //
//    ╚╩╝┴ ┴┘└┘─┴┘└─┘┴└─└─┘┴└─    //
//                                //
//                                //
////////////////////////////////////


contract WND is ERC721Creator {
    constructor() ERC721Creator("Wanderer", "WND") {}
}