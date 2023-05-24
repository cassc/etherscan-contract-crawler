// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BlockBeat Lifetime Terminal Access
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//    __________.__                 __   __________               __       //
//    \______   \  |   ____   ____ |  | _\______   \ ____ _____ _/  |_     //
//     |    |  _/  |  /  _ \_/ ___\|  |/ /|    |  _// __ \\__  \\   __\    //
//     |    |   \  |_(  <_> )  \___|    < |    |   \  ___/ / __ \|  |      //
//     |______  /____/\____/ \___  >__|_ \|______  /\___  >____  /__|      //
//            \/                 \/     \/       \/     \/     \/          //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////


contract BBLAP is ERC721Creator {
    constructor() ERC721Creator("BlockBeat Lifetime Terminal Access", "BBLAP") {}
}