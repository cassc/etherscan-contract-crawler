// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Masks
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//                                    //
//    █▀▄▀█ ██      ▄▄▄▄▄   █  █▀     //
//    █ █ █ █ █    █     ▀▄ █▄█       //
//    █ ▄ █ █▄▄█ ▄  ▀▀▀▀▄   █▀▄       //
//    █   █ █  █  ▀▄▄▄▄▀    █  █      //
//       █     █              █       //
//      ▀     █              ▀        //
//           ▀                        //
//                                    //
//                                    //
//                                    //
////////////////////////////////////////


contract MASK is ERC721Creator {
    constructor() ERC721Creator("Masks", "MASK") {}
}