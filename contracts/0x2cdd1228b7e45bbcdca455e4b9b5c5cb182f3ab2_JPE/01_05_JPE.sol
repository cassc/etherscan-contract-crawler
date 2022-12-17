// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Jack Payne Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//        ____  ____ ___  ______  ___     //
//    ---/-__-\/-__-`/-/-/-/-__-\/-_-\    //
//    --/-/_/-/-/_/-/-/_/-/-/-/-/--__/    //
//    -/-.___/\__,_/\__,-/_/-/_/\___/-    //
//    /_/          /____/                 //
//                                        //
//                                        //
////////////////////////////////////////////


contract JPE is ERC1155Creator {
    constructor() ERC1155Creator("Jack Payne Editions", "JPE") {}
}