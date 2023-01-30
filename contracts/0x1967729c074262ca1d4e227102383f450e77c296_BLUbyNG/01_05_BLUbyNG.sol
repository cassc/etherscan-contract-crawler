// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: History book BLU. Two months in 2022
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////
//                                                                      //
//                                                                      //
//                                                                      //
//    __________.____     ____ ______.          _______    ________     //
//    \______   \    |   |    |   \_ |__ ___.__.\      \  /  _____/     //
//     |    |  _/    |   |    |   /| __ <   |  |/   |   \/   \  ___     //
//     |    |   \    |___|    |  / | \_\ \___  /    |    \    \_\  \    //
//     |______  /_______ \______/  |___  / ____\____|__  /\______  /    //
//            \/        \/             \/\/            \/        \/     //
//                                                                      //
//                                                                      //
//                                                                      //
//////////////////////////////////////////////////////////////////////////


contract BLUbyNG is ERC721Creator {
    constructor() ERC721Creator("History book BLU. Two months in 2022", "BLUbyNG") {}
}