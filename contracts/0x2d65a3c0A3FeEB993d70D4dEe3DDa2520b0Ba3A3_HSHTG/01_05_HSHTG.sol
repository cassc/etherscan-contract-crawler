// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Saul G - #hashtag (feat. Metth)
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////
//                                                                        //
//                                                                        //
//                                                                        //
//       _  _   .__                     .__      __                       //
//    __| || |__|  |__  _____     ______|  |__ _/  |_ _____     ____      //
//    \   __   /|  |  \ \__  \   /  ___/|  |  \\   __\\__  \   / ___\     //
//     |  ||  | |   Y  \ / __ \_ \___ \ |   Y  \|  |   / __ \_/ /_/  >    //
//    /_  ~~  _\|___|  /(____  //____  >|___|  /|__|  (____  /\___  /     //
//      |_||_|       \/      \/      \/      \/            \//_____/      //
//                                                                        //
//                                                                        //
//                                                                        //
////////////////////////////////////////////////////////////////////////////


contract HSHTG is ERC721Creator {
    constructor() ERC721Creator("Saul G - #hashtag (feat. Metth)", "HSHTG") {}
}