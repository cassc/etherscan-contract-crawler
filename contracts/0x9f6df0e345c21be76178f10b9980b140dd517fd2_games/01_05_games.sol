// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DISTANT MEMORIES
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////
//                                                                                       //
//                                                                                       //
//    ________________88                                                                 //
//    _______________8888                                                                //
//    ______88______8888888                                                              //
//    _______8888888888888888888888                                                      //
//    ________8888888888888888888                                                        //
//    ________888888888888888888                                                         //
//    _____8888888888888888888_______________________________¶¶¶¶¶¶                      //
//    _888888888888888888888888888_____________________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶                   //
//    _______888888888888888888888888________________¶¶¶¶¶¶¶1111111¶¶¶¶¶¶¶               //
//    _________888888883333333¶¶¶¶¶¶¶¶¶¶¶¶_________¶¶¶¶¶111111111111111¶¶¶¶              //
//    _________88888_¶¶¶¶¶33333¶¶1111111¶¶¶¶¶¶¶¶¶¶¶¶¶¶111111111111111111¶¶¶¶             //
//    _________888___¶¶¶¶333333¶¶111111¶1¶¶¶XXXXXXX¶¶¶¶¶11111111111111111¶¶¶             //
//    _____________¶¶¶111¶¶¶¶¶¶11111¶¶1111¶¶XXXXXXXXXXXX¶¶¶¶1111111111111¶¶¶             //
//    ____________¶¶¶1111111111¶¶¶¶111111¶¶XXXXXXXXXXXXXXXXX¶¶¶1111111111¶¶¶¶¶           //
//    ___________¶¶¶¶¶¶¶¶¶¶¶¶1111111111¶¶¶XXXXXXXXXXXXXXXXXXXX¶¶¶1111111111¶¶¶¶¶¶        //
//    __________¶¶¶X¶¶1111111111111¶¶¶¶XXXXXXXXXXXXXXXXXXXXXXXXX¶¶¶111111111111¶¶¶¶      //
//    ________¶¶¶XXXX¶¶¶¶¶¶¶¶¶¶¶¶¶XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX¶¶1111111111111¶¶¶     //
//    _______¶¶¶XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX¶¶1111111111111¶¶¶    //
//    ______¶¶¶XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX¶¶111111111111¶¶¶    //
//    _____¶¶¶XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX¶¶11111111111¶¶¶    //
//    _____¶¶¶XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX¶¶111111111¶¶¶¶    //
//    ____¶¶¶XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX¶¶11111111¶¶¶¶     //
//    ____¶¶¶XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX¶¶1111¶¶¶¶¶       //
//    ____¶¶¶XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX¶¶¶¶¶¶¶¶          //
//    ____¶¶¶XXXXXXXXXXXXXXXXXXXXXXXX¶¶¶¶XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX¶¶¶               //
//    _____¶¶¶XXXXX¶¶XXXXXXXXXXXXX¶¶¶¶XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX¶¶¶                //
//    _____¶¶¶¶XXXX¶¶¶¶¶XXXXXXXXX¶¶XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX¶¶¶                //
//    ______¶¶¶XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX¶¶¶                 //
//    _______¶¶¶XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX¶¶¶                  //
//    _________¶¶¶XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX¶¶¶                   //
//    __________¶¶¶¶XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX¶¶¶¶                    //
//    ______¶¶¶¶¶¶¶¶¶¶XXXXXXXXXXXXXXXXXXXXXXXXX¶¶¶¶¶¶¶¶¶¶¶XXXXX¶¶3¶¶¶¶                   //
//    __¶¶¶¶¶¶333¶¶¶¶3¶¶¶XXXXXXXXXXXXXXXXXXX¶¶¶333333333333¶¶¶¶3333¶¶¶¶                  //
//    _¶¶¶¶3333333333¶¶33¶¶¶XXXXXXXXXXXXXXX¶¶33333333333333333¶33333¶¶¶¶                 //
//    ¶¶¶¶3333333333333333333¶¶¶¶¶XXXXXXXX¶¶3333333333333333333333333¶¶¶                 //
//    ¶¶¶¶333333333333333333333333¶¶¶¶¶¶¶¶¶¶333333333333333333333333¶¶¶¶                 //
//    ¶¶¶¶¶333333333333333333333333¶¶¶¶__¶¶¶¶3333333333333333333333¶¶¶¶                  //
//    __¶¶¶¶3333333333333333333¶¶¶¶¶¶______¶¶¶¶¶333333333333333¶¶¶¶¶¶                    //
//    ____¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶____________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶                       //
//    _______¶¶¶¶¶¶¶¶¶¶¶__________________________¶¶¶¶¶¶¶¶¶¶                             //
//                                                                                       //
//                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////


contract games is ERC721Creator {
    constructor() ERC721Creator("DISTANT MEMORIES", "games") {}
}