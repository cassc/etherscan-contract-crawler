// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Limited Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                                                                      //
//                                                                                      //
//       __     ______     __  __     __   __                                           //
//      /\ \   /\  __ \   /\ \_\ \   /\ "-.\ \                                          //
//     _\_\ \  \ \ \/\ \  \ \  __ \  \ \ \-.  \                                         //
//    /\_____\  \ \_____\  \ \_\ \_\  \ \_\\"\_\                                        //
//    \/_____/   \/_____/   \/_/\/_/   \/_/ \/_/                                        //
//                                                                                      //
//     ______     ______     __  __     ______     ______                               //
//    /\  == \   /\  ___\   /\ \/\ \   /\  ___\   /\  ___\                              //
//    \ \  __<   \ \  __\   \ \ \_\ \  \ \___  \  \ \___  \                             //
//     \ \_\ \_\  \ \_____\  \ \_____\  \/\_____\  \/\_____\                            //
//      \/_/ /_/   \/_____/   \/_____/   \/_____/   \/_____/                            //
//                                                                                      //
//     __         __     __    __     __     ______   ______     _____                  //
//    /\ \       /\ \   /\ "-./  \   /\ \   /\__  _\ /\  ___\   /\  __-.                //
//    \ \ \____  \ \ \  \ \ \-./\ \  \ \ \  \/_/\ \/ \ \  __\   \ \ \/\ \               //
//     \ \_____\  \ \_\  \ \_\ \ \_\  \ \_\    \ \_\  \ \_____\  \ \____-               //
//      \/_____/   \/_/   \/_/  \/_/   \/_/     \/_/   \/_____/   \/____/               //
//                                                                                      //
//     ______     _____     __     ______   __     ______     __   __     ______        //
//    /\  ___\   /\  __-.  /\ \   /\__  _\ /\ \   /\  __ \   /\ "-.\ \   /\  ___\       //
//    \ \  __\   \ \ \/\ \ \ \ \  \/_/\ \/ \ \ \  \ \ \/\ \  \ \ \-.  \  \ \___  \      //
//     \ \_____\  \ \____-  \ \_\    \ \_\  \ \_\  \ \_____\  \ \_\\"\_\  \/\_____\     //
//      \/_____/   \/____/   \/_/     \/_/   \/_/   \/_____/   \/_/ \/_/   \/_____/     //
//                                                                                      //
//                                                                                      //
//                                                                                      //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////


contract JRLTD is ERC721Creator {
    constructor() ERC721Creator("Limited Editions", "JRLTD") {}
}