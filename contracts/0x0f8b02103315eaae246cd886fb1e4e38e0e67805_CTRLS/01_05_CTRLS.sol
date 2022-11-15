// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: chemtrails
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//                                          //
//      _ |_   _  ._ _ _|_ ._ _. o |  _     //
//     (_ | | (/_ | | | |_ | (_| | | _>     //
//                                          //
//                                          //
//                                          //
//////////////////////////////////////////////


contract CTRLS is ERC721Creator {
    constructor() ERC721Creator("chemtrails", "CTRLS") {}
}