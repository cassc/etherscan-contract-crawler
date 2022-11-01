// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Monday Madness
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//                                            //
//                __        ___  __   __      //
//     |\/|  /\  |  \ |\ | |__  /__` /__`     //
//     |  | /~~\ |__/ | \| |___ .__/ .__/     //
//                                            //
//                                            //
//                                            //
//                                            //
////////////////////////////////////////////////


contract MAD is ERC721Creator {
    constructor() ERC721Creator("Monday Madness", "MAD") {}
}