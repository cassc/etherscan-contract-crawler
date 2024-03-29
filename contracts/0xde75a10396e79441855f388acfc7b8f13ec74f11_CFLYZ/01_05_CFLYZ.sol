// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Checks x Flyz
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                          //
//                                                                                                                          //
//     ______     __  __     ______     ______     __  __        __  __        ______   __         __  __     ______        //
//    /\  ___\   /\ \_\ \   /\  ___\   /\  ___\   /\ \/ /       /\_\_\_\      /\  ___\ /\ \       /\ \_\ \   /\___  \       //
//    \ \ \____  \ \  __ \  \ \  __\   \ \ \____  \ \  _"-.     \/_/\_\/_     \ \  __\ \ \ \____  \ \____ \  \/_/  /__      //
//     \ \_____\  \ \_\ \_\  \ \_____\  \ \_____\  \ \_\ \_\      /\_\/\_\     \ \_\    \ \_____\  \/\_____\   /\_____\     //
//      \/_____/   \/_/\/_/   \/_____/   \/_____/   \/_/\/_/      \/_/\/_/      \/_/     \/_____/   \/_____/   \/_____/     //
//                                                                                                                          //
//                                                                                                                          //
//                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CFLYZ is ERC721Creator {
    constructor() ERC721Creator("Checks x Flyz", "CFLYZ") {}
}