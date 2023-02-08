// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Stoners Checks
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//    ┌─┐┌┬┐┌─┐┌┐┌┌─┐┬─┐┌─┐  ┌─┐┬ ┬┌─┐┌─┐┬┌─┌─┐    //
//    └─┐ │ │ ││││├┤ ├┬┘└─┐  │  ├─┤├┤ │  ├┴┐└─┐    //
//    └─┘ ┴ └─┘┘└┘└─┘┴└─└─┘  └─┘┴ ┴└─┘└─┘┴ ┴└─┘    //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract STCK is ERC1155Creator {
    constructor() ERC1155Creator("Stoners Checks", "STCK") {}
}