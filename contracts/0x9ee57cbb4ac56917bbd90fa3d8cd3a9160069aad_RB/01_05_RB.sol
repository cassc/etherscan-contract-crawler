// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Renaissance Bots
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                   ..                   ..                                                      //
//                                                  :BB7                 ~BB~                                                     //
//                                                  :BB7                 ~BB~                                                     //
//                                                  :BB?                 ~BB~                                                     //
//                                                  :BB?                 ~BB~                                                     //
//                                                  :BB? 7!!!!!!!!!!!!!! ^BB~                                                     //
//                                                  :B#?.BBBBBBBBBBBBBBB.^##!                                                     //
//                                                   !7^.BBBBBBBBBBBBBBB..77:                                                     //
//                                                      .BBBP5PBBBBGBBBB.                                                         //
//                                                      .BY.   :PBJ :GBB.                                                         //
//                         ~Y~.                         .B~     ?BY.~GBB.                         .!Y^                            //
//                        ?BBBBP?^.                     .BG7:.^?BBY.~GBB.                     .~JGBBBB!                           //
//                       ^PGBBBBBBG57:                  .BBBBBBBBBBBBBBB.                 .^?PBBBBBBBG5:                          //
//                         .^?PBBBBBBBGY!.              .BBBBBBBBBBBBBBB.              :75GBBBBBBBP?^                             //
//                             .~JGBBBBBBBPJ~.          .BBBBBBBBBBBBBBB.          .~YGBBBBBBBPJ~.                                //
//                                 :!5GBBBBBBBP?^.      .777777777777777.      .^?PBBBBBBBGY!.                                    //
//                                     ^?PBBBBBBBG57PGGGGPPPPPPPPPPPPPPPGGGG575GBBBBBBG57:                                        //
//                                        .^?GBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBP?^.                                           //
//                                         :7PBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBP!.                                            //
//                                     .!YGBBBBBBBPJGBBBBBBBBBBBBBBBBBBBBBBBPJGBBBBBBBGJ~.                                        //
//                                 .~JPBBBBBBBGY~.  5BBBBBBBBBBBBBBBBBBBBBBBY  .!YGBBBBBBBP?^.                                    //
//                              ^?PBBBBBBBG57:      5BBBBBBBBBBBBBBBBBBBBBBBY      :75BBBBBBBG57:                                 //
//                          :!5GBBBBBBBP?^.         5BBBBBBBBBBBBBBBBBBBBBBBY         .^JPBBBBBBBGY!.                             //
//                       :YGBBBBBBBGJ~.             5BBBBBBBBBBBBBBBBBBBBBBBY             .~YGBBBBBBBPJ.                          //
//                        YBBBBGY!.                 5BBBBBBBBBBBBBBBBBBBBBBBY                 :75GBBBB?                           //
//                         7P7:                     5BBBBBBBBBBBBBBBBBBBBBBBY                    .^?P~                            //
//                                                  5BBBBBBBBBBBBBBBBBBBBBBBY                                                     //
//                                                  5BBBBBBBBBBBBBBBBBBBBBBBY                                                     //
//                                                  5BBBBBBBBBBBBBBBBBBBBBBBY                                                     //
//                                                  5BBBBBBBBBBBBBBBBBBBBBBBY                                                     //
//                                                 ~GBBBBBBBBBBBBBBBBBBBBBBBP                                                     //
//                                                JBBBBBBBBBBBBBBBBBBBBBBBBBBP.                                                   //
//                                              :PBBBBBBBBBBBBBBBBBBBBBBBBBBBBB~                                                  //
//                                             !BBBBBBBBGBBBBBBBBBBBBBBGBBBBBBBBJ                                                 //
//                                            JBBBBBBBB75BBBBBBBBBBBBBBG!PBBBBBBBP:                                               //
//                                          :PBBBBBBBG:.BBBBBBBPJBBBBBBB~ YBBBBBBBB!                                              //
//                                         !BBBBBBBBY. 7BBBBBBB!.BBBBBBBP  !BBBBBBBBY                                             //
//                                        YBBBBBBBB!   GBBBBBBG. YBBBBBBB^  :GBBBBBBBP:                                           //
//                                      :GBBBBBBBG:   ~BBBBBBBJ  ^BBBBBBBY    YBBBBBBBB!                                          //
//                                     !BBBBBBBBY     5BBBBBBB:   PBBBBBBB.    !BBBBBBBBY                                         //
//                                   .YBBBBBBBB!     .BBBBBBBP    7BBBBBBB7     :PBBBBBBBG:                                       //
//                                  :GBBBBBBBP:      ?BBBBBBB~    .BBBBBBBG       JBBBBBBBB7                                      //
//                                 7BBBBBBBBJ        GBBBBBBG      YBBBBBBB^       !BBBBBBBB5.                                    //
//                                :5GBBBBBB!        ~BBBBBBB?      :BBBBBBBY        :PBBBBBGP!                                    //
//                                   :!YGP:         PBBBBBBB:       PBBBBBBB.         JG5?^.                                      //
//                                                 :#BBBBBB5        !#BBBBB#?          .                                          //
//                                                 .~~!7?JY^        .YJ??7!~^                                                     //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract RB is ERC721Creator {
    constructor() ERC721Creator("The Renaissance Bots", "RB") {}
}