// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Social Anxiety
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//                                              //
//                                              //
//      _     __  __           _____  _____     //
//     | |   |  \/  |   /\    / ____|/ ____|    //
//     | |__ | \  / |  /  \  | (___ | |         //
//     | '_ \| |\/| | / /\ \  \___ \| |         //
//     | |_) | |  | |/ ____ \ ____) | |____     //
//     |_.__/|_|  |_/_/    \_\_____/ \_____|    //
//                                              //
//                                              //
//                                              //
//                                              //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract SA is ERC721Creator {
    constructor() ERC721Creator("Social Anxiety", "SA") {}
}