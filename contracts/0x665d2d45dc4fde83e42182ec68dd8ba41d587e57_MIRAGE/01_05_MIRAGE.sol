// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Soft Mirage
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//                                                        //
//     ##      ##  #      # #  #                          //
//    #   ###  #  ###     ###     ###  ## ### ###         //
//     #  # # ###  #      ###  #  #   # # # # ##          //
//      # ###  #   ##     # #  ## #   ###  ## ###         //
//    ##      ##          # #             ###             //
//                                                        //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract MIRAGE is ERC721Creator {
    constructor() ERC721Creator("Soft Mirage", "MIRAGE") {}
}