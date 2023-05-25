// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Celestial Blackout
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//      _             _           _                   //
//     (_)           | |         | |                  //
//      _  _ __ ___  | | __ __ _ | |_  ___            //
//     | || '_ ` _ \ | |/ // _` || __|/ _ \           //
//     | || | | | | ||   <| (_| || |_|  __/           //
//     |_||_| |_| |_||_|\_\\__,_| \__|\___|           //
//                                                    //
//    minimalist and gradient collection by imkate    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract CBLK is ERC721Creator {
    constructor() ERC721Creator("Celestial Blackout", "CBLK") {}
}