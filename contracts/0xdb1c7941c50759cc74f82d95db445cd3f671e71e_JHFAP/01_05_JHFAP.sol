// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: James Hurley - Fine Art Photography
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                 //
//                                                                                                                 //
//                                                                                                                 //
//                                                                                                                 //
//                                                  __             _           _              _        _           //
//      | _ __  _  _    |_|    __ |  _  \/   ---   |_  o __  _    |_| ___|_   |_)|_  _ _|_ _ (_| __ _ |_)|_  \/    //
//    \_|(_||||(/__>    | ||_| |  | (/_ /          |   | | |(/_   | | |  |_   |  | |(_) |_(_)__| | (_||  | | /     //
//                                                                                                                 //
//                                                                                                                 //
//                                                                                                                 //
//                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract JHFAP is ERC721Creator {
    constructor() ERC721Creator("James Hurley - Fine Art Photography", "JHFAP") {}
}