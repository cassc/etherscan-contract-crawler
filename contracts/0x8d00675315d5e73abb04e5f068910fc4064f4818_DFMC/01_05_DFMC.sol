// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DeadFormatMusicClub
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//                                                                          //
//                                                                          //
//    ·▄▄▄▄  ▄▄▄ . ▄▄▄· ·▄▄▄▄     ·▄▄▄      ▄▄▄  • ▌ ▄ ·.  ▄▄▄· ▄▄▄▄▄       //
//    ██▪ ██ ▀▄.▀·▐█ ▀█ ██▪ ██    ▐▄▄·▪     ▀▄ █··██ ▐███▪▐█ ▀█ •██         //
//    ▐█· ▐█▌▐▀▀▪▄▄█▀▀█ ▐█· ▐█▌   ██▪  ▄█▀▄ ▐▀▀▄ ▐█ ▌▐▌▐█·▄█▀▀█  ▐█.▪       //
//    ██. ██ ▐█▄▄▌▐█ ▪▐▌██. ██    ██▌.▐█▌.▐▌▐█•█▌██ ██▌▐█▌▐█ ▪▐▌ ▐█▌·       //
//    ▀▀▀▀▀•  ▀▀▀  ▀  ▀ ▀▀▀▀▀•  ▀ ▀▀▀  ▀█▄▀▪.▀  ▀▀▀  █▪▀▀▀ ▀  ▀  ▀▀▀  ▀     //
//    • ▌ ▄ ·. ▄• ▄▌.▄▄ · ▪   ▄▄·     ▄▄· ▄▄▌  ▄• ▄▌▄▄▄▄·                   //
//    ·██ ▐███▪█▪██▌▐█ ▀. ██ ▐█ ▌▪   ▐█ ▌▪██•  █▪██▌▐█ ▀█▪                  //
//    ▐█ ▌▐▌▐█·█▌▐█▌▄▀▀▀█▄▐█·██ ▄▄   ██ ▄▄██▪  █▌▐█▌▐█▀▀█▄                  //
//    ██ ██▌▐█▌▐█▄█▌▐█▄▪▐█▐█▌▐███▌   ▐███▌▐█▌▐▌▐█▄█▌██▄▪▐█                  //
//    ▀▀  █▪▀▀▀ ▀▀▀  ▀▀▀▀ ▀▀▀·▀▀▀  ▀ ·▀▀▀ .▀▀▀  ▀▀▀ ·▀▀▀▀                   //
//                                                                          //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx                 //
//                                                                          //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx                 //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx                 //
//    xxxxxxxxxxxx                     xxxxxxxxxxxxxxxxxxxxx                //
//    xxxxxxxxxxxx   x x         x x   xxxxxxxxxxxxxxxxxxxxx                //
//    xxxxxxxxxxxx    x     x     x    xxxxxxxxxxxxxxxxxxxxx                //
//    xxxxxxxxxxxx   x x   xxx   x x   xxxxxxxxxxxxxxxxxxxxx                //
//    xxxxxxxxxxxx                     xxxxxxxxxxxxxxxxxxxxx                //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx                 //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx                 //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx                 //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx                 //
//                                                                          //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx                 //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx                 //
//                                                                          //
//                                                                          //
//     ▐ ▄       ▄▄▄▄▄ ▄ .▄▪   ▐ ▄  ▄▄ •     ▄▄▄ . ▌ ▐·▄▄▄ .▄▄▄             //
//    •█▌▐█▪     •██  ██▪▐███ •█▌▐█▐█ ▀ ▪    ▀▄.▀·▪█·█▌▀▄.▀·▀▄ █·           //
//    ▐█▐▐▌ ▄█▀▄  ▐█.▪██▀▐█▐█·▐█▐▐▌▄█ ▀█▄    ▐▀▀▪▄▐█▐█•▐▀▀▪▄▐▀▀▄            //
//    ██▐█▌▐█▌.▐▌ ▐█▌·██▌▐▀▐█▌██▐█▌▐█▄▪▐█    ▐█▄▄▌ ███ ▐█▄▄▌▐█•█▌           //
//    ▀▀ █▪ ▀█▄▀▪ ▀▀▀ ▀▀▀ ·▀▀▀▀▀ █▪·▀▀▀▀      ▀▀▀ . ▀   ▀▀▀ .▀  ▀           //
//    ▄▄▄  ▄▄▄ . ▄▄▄· ▄▄▌  ▄▄▌   ▄· ▄▌                                      //
//    ▀▄ █·▀▄.▀·▐█ ▀█ ██•  ██•  ▐█▪██▌                                      //
//    ▐▀▀▄ ▐▀▀▪▄▄█▀▀█ ██▪  ██▪  ▐█▌▐█▪                                      //
//    ▐█•█▌▐█▄▄▌▐█ ▪▐▌▐█▌▐▌▐█▌▐▌ ▐█▀·.                                      //
//    .▀  ▀ ▀▀▀  ▀  ▀ .▀▀▀ .▀▀▀   ▀ •                                       //
//    ·▄▄▄▄  ▪  ▄▄▄ ..▄▄ ·                                                  //
//    ██▪ ██ ██ ▀▄.▀·▐█ ▀.                                                  //
//    ▐█· ▐█▌▐█·▐▀▀▪▄▄▀▀▀█▄                                                 //
//    ██. ██ ▐█▌▐█▄▄▌▐█▄▪▐█                                                 //
//    ▀▀▀▀▀• ▀▀▀ ▀▀▀  ▀▀▀▀                                                  //
//                                                                          //
//                                                                          //
//                                                                          //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////


contract DFMC is ERC1155Creator {
    constructor() ERC1155Creator() {}
}