// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Illusory World by Stephan Vasement
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//                                                       //
//    .___.__  .__                                       //
//    |   |  | |  |  __ __  _________________ ___.__.    //
//    |   |  | |  | |  |  \/  ___/  _ \_  __ <   |  |    //
//    |   |  |_|  |_|  |  /\___ (  <_> )  | \/\___  |    //
//    |___|____/____/____//____  >____/|__|   / ____|    //
//                             \/             \/         //
//                                                       //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract Illusory is ERC721Creator {
    constructor() ERC721Creator("Illusory World by Stephan Vasement", "Illusory") {}
}