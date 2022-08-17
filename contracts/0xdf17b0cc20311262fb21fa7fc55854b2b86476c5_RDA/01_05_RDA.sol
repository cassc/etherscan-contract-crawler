// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Russ Digital Art
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//     ____  __ __  _____ _____                           //
//    |    \|  |  |/ ___// ___/                           //
//    |  D  )  |  (   \_(   \_                            //
//    |    /|  |  |\__  |\__  |                           //
//    |    \|  :  |/  \ |/  \ |                           //
//    |  .  \     |\    |\    |                           //
//    |__|\_|\__,_| \___| \___|                           //
//                                                        //
//     ___    ____   ____  ____  ______   ____  _         //
//    |   \  |    | /    ||    ||      | /    || |        //
//    |    \  |  | |   __| |  | |      ||  o  || |        //
//    |  D  | |  | |  |  | |  | |_|  |_||     || |___     //
//    |     | |  | |  |_ | |  |   |  |  |  _  ||     |    //
//    |     | |  | |     | |  |   |  |  |  |  ||     |    //
//    |_____||____||___,_||____|  |__|  |__|__||_____|    //
//                                                        //
//      ____  ____  ______                                //
//     /    ||    \|      |                               //
//    |  o  ||  D  )      |                               //
//    |     ||    /|_|  |_|                               //
//    |  _  ||    \  |  |                                 //
//    |  |  ||  .  \ |  |                                 //
//    |__|__||__|\_| |__|                                 //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract RDA is ERC721Creator {
    constructor() ERC721Creator("Russ Digital Art", "RDA") {}
}