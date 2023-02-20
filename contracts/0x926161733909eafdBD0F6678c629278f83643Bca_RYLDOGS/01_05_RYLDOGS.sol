// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Royal Dogs
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    ┬─┐┌─┐┬ ┬┌─┐┬        //
//    ├┬┘│ │└┬┘├─┤│        //
//    ┴└─└─┘ ┴ ┴ ┴┴─┘      //
//    ┌┬┐┌─┐┌─┐┌─┐         //
//     │││ ││ ┬└─┐bm       //
//    ─┴┘└─┘└─┘└─┘         //
//                         //
//                         //
/////////////////////////////


contract RYLDOGS is ERC721Creator {
    constructor() ERC721Creator("Royal Dogs", "RYLDOGS") {}
}