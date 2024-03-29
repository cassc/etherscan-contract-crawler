// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SelfLust
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////
//                                                                              //
//                                                                              //
//    .____                    __            _____               .__   __       //
//    |    |    __ __  _______/  |_    _____/ ____\   ____  __ __|  |_/  |_     //
//    |    |   |  |  \/  ___/\   __\  /  _ \   __\  _/ ___\|  |  \  |\   __\    //
//    |    |___|  |  /\___ \  |  |   (  <_> )  |    \  \___|  |  /  |_|  |      //
//    |_______ \____//____  > |__|    \____/|__|     \___  >____/|____/__|      //
//            \/          \/                             \/                     //
//                                                                              //
//                                                                              //
//////////////////////////////////////////////////////////////////////////////////


contract SFLT is ERC721Creator {
    constructor() ERC721Creator("SelfLust", "SFLT") {}
}