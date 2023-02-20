// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Modern Apes
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                       //
//                                                                                                                                       //
//    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////     //
//    //                                                                                                                          //     //
//    //                                                                                                                          //     //
//    //      _______ _            __  __           _                                                                             //     //
//    //     |__   __| |          |  \/  |         | |                     /\                                                     //     //
//    //        | |  | |__   ___  | \  / | ___   __| | ___ _ __ _ __      /  \   _ __   ___  ___                                  //     //
//    //        | |  | '_ \ / _ \ | |\/| |/ _ \ / _` |/ _ \ '__| '_ \    / /\ \ | '_ \ / _ \/ __|                                 //     //
//    //        | |  | | | |  __/ | |  | | (_) | (_| |  __/ |  | | | |  / ____ \| |_) |  __/\__ \                                 //     //
//    //        |_|  |_| |_|\___| |_|  |_|\___/ \__,_|\___|_|  |_| |_| /_/    \_\ .__/ \___||___/                                 //     //
//    //                                                                        | |                                               //     //
//    //                                                                        |_|                                               //     //
//    //    //                                                                                                                    //     //
//    //                                                                                                                          //     //
//    //    MAPES (The Modern Apes), is an interdisciplinary art project where different artistic mediums converge:                //    //
//    //    Visual Arts, Literature and Music.                                                                                     //    //
//    //    There is a limited NFT (non-fungible token) collection of 1671 works of art.                                          //     //
//    //    Each art piece represents a character or an object from a lyrical narrative:                                          //     //
//    //    A script telling a futuristic story in 10 chapters. At the same time, this story is orchestrated by an album          //     //
//    //    consisting of 10 tracks, where various artists collaborate to convey the imagery and the narrative through music.     //     //
//    //                                                                                                                          //     //
//    //    MAPES aims to form an artistic collective, where by owning an NFT, you will be given access to a community that        //    //
//    //    revolves around creation and the unity of knowledge, invitations, contacts and much more.                             //     //
//    //    Through the aforementioned pursuit, you will have access to renowned artists that are each working as active          //     //
//    //    contributors towards the project. More info, please refer at https://modernapes.co/                                   //     //
//    //                                                                                                                          //     //
//    //    //                                                                                                                    //     //
//    //                                                                                                                          //     //
//    //                                                                                                                          //     //
//    //                                                                                                                          //     //
//    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////     //
//                                                                                                                                       //
//                                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MAPES is ERC721Creator {
    constructor() ERC721Creator("The Modern Apes", "MAPES") {}
}