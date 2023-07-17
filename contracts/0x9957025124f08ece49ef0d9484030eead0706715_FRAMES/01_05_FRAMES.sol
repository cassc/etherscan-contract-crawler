// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Frames
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//                                    //
//                                    //
//     ___    __  _  _  _  _  ___     //
//    (   \  /  \( \( )( \/ )(  _)    //
//     ) ) )( () ))  (  \  /  ) _)    //
//    (___/  \__/(_)\_)(__/  (___)    //
//                                    //
//                                    //
//                                    //
//                                    //
////////////////////////////////////////


contract FRAMES is ERC1155Creator {
    constructor() ERC1155Creator("Frames", "FRAMES") {}
}