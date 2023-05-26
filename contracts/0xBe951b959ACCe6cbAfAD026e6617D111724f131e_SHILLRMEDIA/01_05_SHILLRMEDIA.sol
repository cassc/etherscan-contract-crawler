// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SHILLR Media
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                  ^7JYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYJ?~.       //
//                                !5BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBP7.     //
//                               ?BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBY.    //
//                               GBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB^    //
//                               GBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB~    //
//                               GBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB~    //
//                               GBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB^    //
//                               ?BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBY.    //
//                                7PBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBG?.     //
//                                 .^7?JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ?7~.       //
//                                                                                                            //
//                                                                                                            //
//        :~!!!!!!!!!~:                                                                                       //
//      ~YGBBBBBBBBBBBBP7.                                                                                    //
//    .YBBBBBBBBBBBBBBBBBP^                                                                                   //
//    ~BBBBBBBBBBBBBBBBBB#?                                                                                   //
//    !BBBBBBBBBBBBBBBBBBBJ                                                                                   //
//    !BBBBBBBBBBBBBBBBBBBJ                                                                                   //
//    !BBBBBBBBBBBBBBBBBB#J                                                                                   //
//    :GBBBBBBBBBBBBBBBBBB!                                                                                   //
//     ^5BBBBBBBBBBBBBBBP!                                                                                    //
//       ^?Y555555555Y?~.                                                                                     //
//                                                                                                            //
//                                                                                                            //
//                                   .^^^^^^^^^:.                                                             //
//                                .75GBBBBBBBBBBGY~                                                           //
//                               ^PBBBBBBBBBBBBBBBB5^                                                         //
//                               PBBBBBBBBBBBBBBBBBB5                                                         //
//                               GBBBBBBBBBBBBBBBBBB5                                                         //
//                               GBBBBBBBBBBBBBBBBBB5                                                         //
//                               GBBBBBBBBBBBBBBBBBB5                                                         //
//                               5BBBBBBBBBBBBBBBBBBY                                                         //
//                               :PBBBBBBBBBBBBBBBBY.                                                         //
//                                .!J5GGGGGGGGGP5?^                                                           //
//                                    ..........                                                              //
//                                                                                                            //
//                                                              ..........                                    //
//                                                           ^?5PGGGGGGGGG5?^                                 //
//                                                         .JBBBBBBBBBBBBBBBBY:                               //
//                                                         JBBBBBBBBBBBBBBBBBBP                               //
//                                                         5BBBBBBBBBBBBBBBBBBG.                              //
//                                                         5BBBBBBBBBBBBBBBBBBG.                              //
//                                                         5BBBBBBBBBBBBBBBBBBG.                              //
//                                                         YBBBBBBBBBBBBBBBBBBG.                              //
//                                                         ^PBBBBBBBBBBBBBBBBG~                               //
//                                                          .75GBBBBBBBBBBG5?:                                //
//                                                             .:^^^^^^^^:.                                   //
//                                                                                                            //
//                                                                                                            //
//                                                                                     .~?Y555555555J!:       //
//                                                                                    !PBBBBBBBBBBBBBBGJ:     //
//                                                                                   !BBBBBBBBBBBBBBBBBBP.    //
//                                                                                   ?#BBBBBBBBBBBBBBBBBB^    //
//                                                                                   ?#BBBBBBBBBBBBBBBBBB^    //
//                                                                                   ?#BBBBBBBBBBBBBBBBBB~    //
//                                                                                   ?#BBBBBBBBBBBBBBBBBB^    //
//                                                                                   ^PBBBBBBBBBBBBBBBBBJ     //
//                                                                                    :JGBBBBBBBBBBBBB5!      //
//                                                                                      .^77???????7!^        //
//                                                                                                            //
//                                                                                                            //
//       .^7?JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ?7^                                  //
//     .?PBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB5~                                //
//    .5BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB?                               //
//    !BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBG.                              //
//    !BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBG.                              //
//    !BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBG.                              //
//    !BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB.                              //
//    :PBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBJ                               //
//     :JGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBP!                                //
//       :!JY555555555555555555555555555555555555555555555555555555555555Y?~.                                 //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SHILLRMEDIA is ERC1155Creator {
    constructor() ERC1155Creator("SHILLR Media", "SHILLRMEDIA") {}
}