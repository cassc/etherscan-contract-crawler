// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ultraviolet
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//                                                                    //
//      _   _ _ _                   _       _      _                  //
//     | | | | | |_ _ __ __ ___   _(_) ___ | | ___| |_                //
//     | | | | | __| '__/ _` \ \ / / |/ _ \| |/ _ \ __|               //
//     | |_| | | |_| | | (_| |\ V /| | (_) | |  __/ |_                //
//      \___/|_|\__|_|  \__,_| \_/_|_|\___/|_|\___|\__|               //
//     | |__  _   _    __ _| |__ | | ___ __ (_) ___| | _____ _ __     //
//     | '_ \| | | |  / _` | '_ \| |/ / '_ \| |/ __| |/ / _ \ '__|    //
//     | |_) | |_| | | (_| | |_) |   <| | | | | (__|   <  __/ |       //
//     |_.__/ \__, |  \__,_|_.__/|_|\_\_| |_|_|\___|_|\_\___|_|       //
//            |___/                                                   //
//                                                                    //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract UV is ERC721Creator {
    constructor() ERC721Creator("Ultraviolet", "UV") {}
}