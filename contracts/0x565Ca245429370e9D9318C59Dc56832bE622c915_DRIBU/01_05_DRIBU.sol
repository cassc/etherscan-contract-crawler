// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: dribnet / unit london
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////
//                                                             //
//                                                             //
//         _       _  _               _                        //
//       _| | _ _ <_>| |_ ._ _  ___ _| |_                      //
//      / . || '_>| || . \| ' |/ ._> | |                       //
//      \___||_|  |_||___/|_|_|\___. |_|  (and unit london)    //
//                                                             //
//                                                             //
//                                                             //
/////////////////////////////////////////////////////////////////


contract DRIBU is ERC721Creator {
    constructor() ERC721Creator("dribnet / unit london", "DRIBU") {}
}