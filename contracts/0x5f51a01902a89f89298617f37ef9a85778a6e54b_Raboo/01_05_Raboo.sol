// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rudolf Boogerman
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                           //
//                                                                                           //
//      _____           _       _  __                                                        //
//     |  __ \         | |     | |/ _|                                                       //
//     | |__) |   _  __| | ___ | | |_                                                        //
//     |  _  / | | |/ _` |/ _ \| |  _|                                                       //
//     | | \ \ |_| | (_| | (_) | | |                                                         //
//     |_|__\_\__,_|\__,_|\___/|_|_|                                                         //
//     |  _ \                                                                                //
//     | |_) | ___   ___   __ _  ___ _ __ _ __ ___   __ _ _ __                               //
//     |  _ < / _ \ / _ \ / _` |/ _ \ '__| '_ ` _ \ / _` | '_ \                              //
//     | |_) | (_) | (_) | (_| |  __/ |  | | | | | | (_| | | | |                             //
//     |____/ \___/ \___/ \__, |\___|_|  |_| |_| |_|\__,_|_| |_|                             //
//                         __/ |                                                             //
//                        |___/                                                              //
//                                                                                           //
//     Standalone artworks by mixed media artist Rudolf Boogerman                            //
//     & his alter ego Raboo.                                                                //
//     Twitter: @RudolfBoogerman                                                             //
//     Website: raboo.info                                                                   //
//     linktr.ee/raboo                                                                       //
//                                                                                           //
//                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////


contract Raboo is ERC721Creator {
    constructor() ERC721Creator("Rudolf Boogerman", "Raboo") {}
}