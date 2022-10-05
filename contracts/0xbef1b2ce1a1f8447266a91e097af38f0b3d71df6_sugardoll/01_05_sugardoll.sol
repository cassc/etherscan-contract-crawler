// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SugarDolls
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//                                                        //
//                                    _       _ _         //
//      ___ _   _  __ _  __ _ _ __ __| | ___ | | |___     //
//     / __| | | |/ _` |/ _` | '__/ _` |/ _ \| | / __|    //
//     \__ \ |_| | (_| | (_| | | | (_| | (_) | | \__ \    //
//     |___/\__,_|\__, |\__,_|_|  \__,_|\___/|_|_|___/    //
//                |___/                                   //
//                                                        //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract sugardoll is ERC721Creator {
    constructor() ERC721Creator("SugarDolls", "sugardoll") {}
}