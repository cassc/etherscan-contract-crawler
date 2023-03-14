// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: lashe
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//                                          //
//                                          //
//    .__                .__                //
//    |  | _____    _____|  |__   ____      //
//    |  | \__  \  /  ___/  |  \_/ __ \     //
//    |  |__/ __ \_\___ \|   Y  \  ___/     //
//    |____(____  /____  >___|  /\___  >    //
//              \/     \/     \/     \/     //
//                                          //
//                                          //
//                                          //
//                                          //
//////////////////////////////////////////////


contract lsh is ERC721Creator {
    constructor() ERC721Creator("lashe", "lsh") {}
}