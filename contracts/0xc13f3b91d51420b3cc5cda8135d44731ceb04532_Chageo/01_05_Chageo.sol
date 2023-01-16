// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: chaos géométrique
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    ╔═╗┬ ┬┌─┐┌─┐┌─┐┌─┐    //
//    ║  ├─┤├─┤│ ┬├┤ │ │    //
//    ╚═╝┴ ┴┴ ┴└─┘└─┘└─┘    //
//                          //
//                          //
//////////////////////////////


contract Chageo is ERC721Creator {
    constructor() ERC721Creator(unicode"chaos géométrique", "Chageo") {}
}