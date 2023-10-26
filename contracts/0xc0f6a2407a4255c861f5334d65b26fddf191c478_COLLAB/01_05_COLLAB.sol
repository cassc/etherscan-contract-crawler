// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TheDigitalCoy Collabs - 721
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//    <(O)> THEDIGITALCOY C<(O)>LL@BS <(O)>    //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract COLLAB is ERC721Creator {
    constructor() ERC721Creator("TheDigitalCoy Collabs - 721", "COLLAB") {}
}