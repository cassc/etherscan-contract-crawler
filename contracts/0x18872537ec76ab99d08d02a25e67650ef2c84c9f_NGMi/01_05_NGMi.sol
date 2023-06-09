// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Degen Hours - Pluto & Lucifren
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//     __   __     ______     __    __     __        //
//    /\ "-.\ \   /\  ___\   /\ "-./  \   /\ \       //
//    \ \ \-.  \  \ \ \__ \  \ \ \-./\ \  \ \ \      //
//     \ \_\\"\_\  \ \_____\  \ \_\ \ \_\  \ \_\     //
//      \/_/ \/_/   \/_____/   \/_/  \/_/   \/_/     //
//                                                   //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract NGMi is ERC721Creator {
    constructor() ERC721Creator("Degen Hours - Pluto & Lucifren", "NGMi") {}
}