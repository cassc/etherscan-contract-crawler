// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NFT ACADEMY
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                    //
//                                                                                                    //
//                                                                                                    //
//     _        _______ _________   _______  _______  _______  ______   _______  _______              //
//    ( (    /|(  ____ \\__   __/  (  ___  )(  ____ \(  ___  )(  __  \ (  ____ \(       )|\     /|    //
//    |  \  ( || (    \/   ) (     | (   ) || (    \/| (   ) || (  \  )| (    \/| () () |( \   / )    //
//    |   \ | || (__       | |     | (___) || |      | (___) || |   ) || (__    | || || | \ (_) /     //
//    | (\ \) ||  __)      | |     |  ___  || |      |  ___  || |   | ||  __)   | |(_)| |  \   /      //
//    | | \   || (         | |     | (   ) || |      | (   ) || |   ) || (      | |   | |   ) (       //
//    | )  \  || )         | |     | )   ( || (____/\| )   ( || (__/  )| (____/\| )   ( |   | |       //
//    |/    )_)|/          )_(     |/     \|(_______/|/     \|(______/ (_______/|/     \|   \_/       //
//                                                                                                    //
//                                                                                                    //
//                                                                                                    //
//                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ILoveNFT is ERC721Creator {
    constructor() ERC721Creator("NFT ACADEMY", "ILoveNFT") {}
}