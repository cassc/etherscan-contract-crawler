// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bluebird
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//        ____  __           __    _          __    //
//       / __ )/ /_  _____  / /_  (_)________/ /    //
//      / __  / / / / / _ \/ __ \/ / ___/ __  /     //
//     / /_/ / / /_/ /  __/ /_/ / / /  / /_/ /      //
//    /_____/_/\__,_/\___/_.___/_/_/   \__,_/       //
//                                                  //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract BBD is ERC721Creator {
    constructor() ERC721Creator("Bluebird", "BBD") {}
}