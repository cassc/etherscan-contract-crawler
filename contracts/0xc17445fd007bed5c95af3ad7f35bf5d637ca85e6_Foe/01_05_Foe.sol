// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fencer open editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//                        .==.            //
//                       ()''()-.         //
//            .---.       ;--; /          //
//          .'_:___". _..'.  __'.         //
//          |__ --==|'-''' \'...;         //
//          [  ]  :[|       |---\         //
//          |__| I=[|     .'    '.        //
//          / / ____|     :       '._     //
//         |-/.____.'      | :       :    //
//    snd /___\ /___\      '-'._----'     //
//                                        //
//                                        //
////////////////////////////////////////////


contract Foe is ERC721Creator {
    constructor() ERC721Creator("Fencer open editions", "Foe") {}
}