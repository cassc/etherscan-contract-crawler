// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LIGERcleats World Cup 2022
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                          //
//                                                                                          //
//    .____    .___  ____________________________       .__                 __              //
//    |    |   |   |/  _____/\_   _____|______   \ ____ |  |   ____ _____ _/  |_  ______    //
//    |    |   |   /   \  ___ |    __)_ |       _// ___\|  | _/ __ \\__  \\   __\/  ___/    //
//    |    |___|   \    \_\  \|        \|    |   \  \___|  |_\  ___/ / __ \|  |  \___ \     //
//    |_______ \___|\______  /_______  /|____|_  /\___  >____/\___  >____  /__| /____  >    //
//            \/           \/        \/        \/     \/          \/     \/          \/     //
//                                                                                          //
//                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////


contract LGRC is ERC721Creator {
    constructor() ERC721Creator("LIGERcleats World Cup 2022", "LGRC") {}
}