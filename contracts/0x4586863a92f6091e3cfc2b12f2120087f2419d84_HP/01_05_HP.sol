// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Happy Place
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////
//                                                              //
//                                                              //
//                                                              //
//      _  _                       ___ _                        //
//     | || |__ _ _ __ _ __ _  _  | _ \ |__ _ __ ___            //
//     | __ / _` | '_ \ '_ \ || | |  _/ / _` / _/ -_)           //
//     |_||_\__,_| .__/ .__/\_, | |_| |_\__,_\__\___|           //
//               |_|  |_|   |__/                                //
//                                                              //
//                                                              //
//                                                              //
//                                                              //
//                                                              //
//                                                              //
//                                                              //
//                                                              //
//                                                              //
//                                                              //
//                                                              //
//    Happy Place is a 1/1 3D modeled NFT art collection        //
//    that was inspired by a waking dream through a jungle.     //
//                                                              //
//    by Alyse @ang_gallery                                     //
//                                                              //
//                                                              //
//    - - - - -                                                 //
//                                                              //
//    The Official Smart Contract of Happy Place                //
//    Created by Alyse Gamson                                   //
//                                                              //
//                                                              //
//                                                              //
//////////////////////////////////////////////////////////////////


contract HP is ERC721Creator {
    constructor() ERC721Creator("Happy Place", "HP") {}
}