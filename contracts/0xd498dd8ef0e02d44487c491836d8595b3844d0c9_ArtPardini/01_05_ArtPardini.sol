// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ArtPardini
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//                                                      //
//          __  ___     __        __   __               //
//     /\  |__)  |     |__)  /\  |__) |  \ | |\ | |     //
//    /~~\ |  \  |     |    /~~\ |  \ |__/ | | \| |     //
//                                                      //
//                                                      //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract ArtPardini is ERC721Creator {
    constructor() ERC721Creator("ArtPardini", "ArtPardini") {}
}