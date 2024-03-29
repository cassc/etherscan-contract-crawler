// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: THE AWAKENING
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                         //
//                                                                                                                                         //
//                                                                                                                                         //
//    .___________. __    __   _______         ___   ____    __    ____  ___       __  ___  _______ .__   __.  __  .__   __.   _______     //
//    |           ||  |  |  | |   ____|       /   \  \   \  /  \  /   / /   \     |  |/  / |   ____||  \ |  | |  | |  \ |  |  /  _____|    //
//    `---|  |----`|  |__|  | |  |__         /  ^  \  \   \/    \/   / /  ^  \    |  '  /  |  |__   |   \|  | |  | |   \|  | |  |  __      //
//        |  |     |   __   | |   __|       /  /_\  \  \            / /  /_\  \   |    <   |   __|  |  . `  | |  | |  . `  | |  | |_ |     //
//        |  |     |  |  |  | |  |____     /  _____  \  \    /\    / /  _____  \  |  .  \  |  |____ |  |\   | |  | |  |\   | |  |__| |     //
//        |__|     |__|  |__| |_______|   /__/     \__\  \__/  \__/ /__/     \__\ |__|\__\ |_______||__| \__| |__| |__| \__|  \______|     //
//                                                                                                                                         //
//                                                                                                                                         //
//                                                                                                                                         //
//                                                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SUNRISE is ERC721Creator {
    constructor() ERC721Creator("THE AWAKENING", "SUNRISE") {}
}