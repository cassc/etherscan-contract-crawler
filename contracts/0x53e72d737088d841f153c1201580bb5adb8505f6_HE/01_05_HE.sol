// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Human Error
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//                                                                          //
//     _    _                               ______                          //
//     | |  | |                             |  ____|                        //
//     | |__| |_   _ _ __ ___   __ _ _ __   | |__   _ __ _ __ ___  _ __     //
//     |  __  | | | | '_ ` _ \ / _` | '_ \  |  __| | '__| '__/ _ \| '__|    //
//     | |  | | |_| | | | | | | (_| | | | | | |____| |  | | | (_) | |       //
//     |_|  |_|\__,_|_| |_| |_|\__,_|_| |_| |______|_|  |_|  \___/|_|       //
//                                                                          //
//                                                                          //
//    Art series by Rudolf Boogerman, using AI and image editing to         //
//    express ideas about human nature and (r)evolution.                    //
//                                                                          //
//    Twitter: @RudolfBoogerman                                             //
//    Website: raboo.info                                                   //
//                                                                          //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////


contract HE is ERC721Creator {
    constructor() ERC721Creator("Human Error", "HE") {}
}