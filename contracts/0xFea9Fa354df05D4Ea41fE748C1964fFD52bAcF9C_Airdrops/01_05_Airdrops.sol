// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Himalayan Diaries Airdrop
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                              //
//                                                                                              //
//                                                                                              //
//                                                                                              //
//                                                                                              //
//          db      `7MMF'`7MM"""Mq.  `7MM"""Yb. `7MM"""Mq.   .g8""8q. `7MM"""Mq.  .M"""bgd     //
//         ;MM:       MM    MM   `MM.   MM    `Yb. MM   `MM..dP'    `YM. MM   `MM.,MI    "Y     //
//        ,V^MM.      MM    MM   ,M9    MM     `Mb MM   ,M9 dM'      `MM MM   ,M9 `MMb.         //
//       ,M  `MM      MM    MMmmdM9     MM      MM MMmmdM9  MM        MM MMmmdM9    `YMMNq.     //
//       AbmmmqMA     MM    MM  YM.     MM     ,MP MM  YM.  MM.      ,MP MM       .     `MM     //
//      A'     VML    MM    MM   `Mb.   MM    ,dP' MM   `Mb.`Mb.    ,dP' MM       Mb     dM     //
//    .AMA.   .AMMA..JMML..JMML. .JMM..JMMmmmdP' .JMML. .JMM. `"bmmd"' .JMML.     P"Ybmmd"      //
//                                                                                              //
//                                                                                              //
//                                                                                              //
//                                                                                              //
//                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////


contract Airdrops is ERC721Creator {
    constructor() ERC721Creator("Himalayan Diaries Airdrop", "Airdrops") {}
}