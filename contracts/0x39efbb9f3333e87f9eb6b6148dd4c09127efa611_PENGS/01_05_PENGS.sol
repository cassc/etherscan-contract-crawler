// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Perception Engines
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////
//                                                              //
//                                                              //
//         _       _  _               _                         //
//       _| | _ _ <_>| |_ ._ _  ___ _| |_                       //
//      / . || '_>| || . \| ' |/ ._> | |                        //
//      \___||_|  |_||___/|_|_|\___. |_|  Perception Engines    //
//                                                              //
//                                                              //
//////////////////////////////////////////////////////////////////


contract PENGS is ERC721Creator {
    constructor() ERC721Creator("Perception Engines", "PENGS") {}
}