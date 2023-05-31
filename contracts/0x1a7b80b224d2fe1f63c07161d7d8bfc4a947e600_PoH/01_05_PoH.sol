// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: It's a Process
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//    It's a process.                                   //
//    To heal.                                          //
//    To begin healing.                                 //
//                                                      //
//    An ocean surrounds my soul.                       //
//    It is my home, my scared place                    //
//    There is no sound here                            //
//    Save that of memories and distant dreams.         //
//    There is no outlet here                           //
//    No bottle to suppress these emotions in.          //
//                                                      //
//    So my pain must be processed                      //
//    Must be purified and tempered.                    //
//    Because if something causes violent waves         //
//    Then I lose which way is up.                      //
//    And which is down.                                //
//                                                      //
//    So I sit with my pain                             //
//    Let it in around me.                              //
//    I listen to it's words, cries and anger           //
//    And how it's afraid to feel again.                //
//    I let it sleep, giving it its own current         //
//    I let it sink deep, reassuring that it's okay.    //
//    And slowly it begins to realize                   //
//    That even pain has a place here.                  //
//                                                      //
//    It's a process.                                   //
//    And I'm learning.                                 //
//                                                      //
//                                                      //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract PoH is ERC1155Creator {
    constructor() ERC1155Creator("It's a Process", "PoH") {}
}