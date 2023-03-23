// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Artillity Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//    .                                                                                                             //
//    .                                                                                                             //
//    .                                                                                                             //
//    .                                                                                                             //
//    .                                                                                                             //
//    .                                                                                                             //
//    .                                                                                                             //
//    .                                                                                                             //
//    .                                                                                                             //
//    .                                                                                                             //
//    .                                                                                                             //
//    .                                                                                                             //
//    .                                               !PP?                                                          //
//    .                                              ~&@@@!                                                         //
//    .                                             [email protected]@#: .PB!                                                   //
//    .                                             [email protected]  [email protected]  [email protected]#:                                                  //
//    .                                            [email protected]  ^&@7  [email protected]                                                  //
//    .                                           [email protected]&^    [email protected]&^ :&@7                                                 //
//    .                                          ^&@7  ^^  [email protected]  [email protected]&:                                                //
//    .                                         [email protected]  [email protected]#. :#@J  [email protected]                                                //
//    .                                         [email protected]  ^&@7   [email protected]&~ :#@?                                               //
//    .                                        [email protected]#: [email protected]     [email protected] [email protected]&^                                              //
//    .                                       [email protected]@~  [email protected]#.     [email protected]  [email protected]                                             //
//    .                                      :#@?  [email protected]@~       [email protected]@! [email protected]                                             //
//    .                                     [email protected]  :#@J         [email protected] [email protected]@^                                            //
//    .                                     [email protected]  [email protected]           ~^   :^                                             //
//    .                                    [email protected]&^  [email protected]&: ^YYYYYYYYYJJYYYJJJ7                                           //
//    .                                   [email protected]@!  ^&@!  ^5555555555555555&@Y                                          //
//    .                                  :#@J  [email protected]                    ~&@7                                         //
//    .                                  [email protected]   [email protected] ^5555555555555555~  [email protected]&^                                        //
//    .                                 [email protected]  [email protected]&^  :[email protected]&:  [email protected]                                       //
//    .                                [email protected]&^  :#@?                   [email protected]  [email protected]                                       //
//    .                               ^&@7   [email protected]                    :#@7  ^&@?                                      //
//    .                              :[email protected]   :!!.                     :!:   [email protected]@~                                     //
//    .                              [email protected]   :BB:                             [email protected]                                     //
//    .                               :     ::                               :.                                     //
//    .                                                                                                             //
//    .                                                                                                             //
//    .                                                                                                             //
//    .                                                                                                             //
//    .                                                                                                             //
//    .                                                                                                             //
//    .                                                                                                             //
//    .                                                                                                             //
//    .                                                                                                             //
//    .                                                                                                             //
//    .                                                                                                             //
//    .                                                                                                             //
//    .                                                                                                             //
//    .                                                                                                             //
//                                                                                                                  //
//                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ARTILLITY1155 is ERC1155Creator {
    constructor() ERC1155Creator("Artillity Editions", "ARTILLITY1155") {}
}