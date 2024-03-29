// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Face of Mende
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////
//                                                                  //
//                                                                  //
//                                                                  //
//                _____                     .___                    //
//               /     \   ____   ____    __| _/____                //
//              /  \ /  \_/ __ \ /    \  / __ |/ __ \               //
//             /    Y    \  ___/|   |  \/ /_/ \  ___/               //
//             \____|__  /\___  >___|  /\____ |\___  >              //
//                     \/     \/     \/      \/    \/               //
//               _________                      __                  //
//              /   _____/ _____ _____ ________/  |_                //
//              \_____  \ /     \\__  \\_  __ \   __\               //
//              /        \  Y Y  \/ __ \|  | \/|  |                 //
//             /_______  /__|_|  (____  /__|   |__|                 //
//                     \/      \/     \/                            //
//    _________                __                        __         //
//    \_   ___ \  ____   _____/  |_____________    _____/  |_       //
//    /    \  \/ /  _ \ /    \   __\_  __ \__  \ _/ ___\   __\      //
//    \     \___(  <_> )   |  \  |  |  | \// __ \\  \___|  |        //
//     \______  /\____/|___|  /__|  |__|  (____  /\___  >__|        //
//            \/            \/                 \/     \/            //
//                                                                  //
//    www.instagram.com/mende                               11#     //
//                                                                  //
//                                                                  //
//////////////////////////////////////////////////////////////////////


contract MENDE is ERC1155Creator {
    constructor() ERC1155Creator("Face of Mende", "MENDE") {}
}