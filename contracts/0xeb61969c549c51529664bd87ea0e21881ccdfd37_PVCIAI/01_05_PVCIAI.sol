// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Paveci's Precisionism
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////
//                                                                       //
//                                                                       //
//    ╔╦╗┬ ┬┌─┐  ╔═╗┌─┐┬  ┬┌─┐┌─┐┬┌─┐  ╔═╗┬─┐┌─┐┌─┐┬┌─┐┬┌─┐┌┐┌┬┌─┐┌┬┐    //
//     ║ ├─┤├┤   ╠═╝├─┤└┐┌┘├┤ │  │└─┐  ╠═╝├┬┘├┤ │  │└─┐││ │││││└─┐│││    //
//     ╩ ┴ ┴└─┘  ╩  ┴ ┴ └┘ └─┘└─┘┴└─┘  ╩  ┴└─└─┘└─┘┴└─┘┴└─┘┘└┘┴└─┘┴ ┴    //
//                                                                       //
//                                                                       //
//                                                                       //
//                                                                       //
///////////////////////////////////////////////////////////////////////////


contract PVCIAI is ERC721Creator {
    constructor() ERC721Creator("The Paveci's Precisionism", "PVCIAI") {}
}