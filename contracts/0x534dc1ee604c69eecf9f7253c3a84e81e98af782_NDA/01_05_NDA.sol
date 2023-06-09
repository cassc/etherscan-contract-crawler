// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nathan Dawson Art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////
//                                                                                       //
//                                                                                       //
//                                                                                       //
//              ___                    __             __   __                __  ___     //
//    |\ |  /\   |  |__|  /\  |\ |    |  \  /\  |  | /__` /  \ |\ |     /\  |__)  |      //
//    | \| /~~\  |  |  | /~~\ | \|    |__/ /~~\ |/\| .__/ \__/ | \|    /~~\ |  \  |      //
//                                                                                       //
//                                                                                       //
//                                                                                       //
//                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////


contract NDA is ERC721Creator {
    constructor() ERC721Creator("Nathan Dawson Art", "NDA") {}
}