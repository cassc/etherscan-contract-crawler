// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: mellow_memes
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//                    _ _                          _       //
//                   | | |                        | |      //
//     _ __ ___   ___| | | _____      _____  _   _| |_     //
//    | '_ ` _ \ / _ \ | |/ _ \ \ /\ / / _ \| | | | __|    //
//    | | | | | |  __/ | | (_) \ V  V / (_) | |_| | |_     //
//    |_| |_| |_|\___|_|_|\___/ \_/\_/ \___/ \__,_|\__|    //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract MMM is ERC1155Creator {
    constructor() ERC1155Creator("mellow_memes", "MMM") {}
}