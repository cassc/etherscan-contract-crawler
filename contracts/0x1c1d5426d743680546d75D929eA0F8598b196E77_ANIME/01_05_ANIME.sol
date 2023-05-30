// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: nyansuke animation
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//    (^・ω・^ )( ^・ω・^)(^・ω・^ )( ^・ω・^)    //
//                                        //
//                                        //
////////////////////////////////////////////


contract ANIME is ERC1155Creator {
    constructor() ERC1155Creator("nyansuke animation", "ANIME") {}
}