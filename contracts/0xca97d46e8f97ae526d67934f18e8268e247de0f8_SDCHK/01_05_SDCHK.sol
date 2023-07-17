// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sandchuck
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                          //
//                                                                                          //
//                                                                                          //
//                                 _;;www;;_                                                //
//                               #RRRRRRRRRRRRmc;;;;c,__                                    //
//                              [email protected]_                            //
//                           _,JRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRWw,                       //
//                      [email protected]_                   //
//                   gRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRw                 //
//                 #RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRW_              //
//                0RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRW             //
//               [RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR~           //
//              #RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRp          //
//            ,RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRL ?0RRRRRRRRRRRRRRRRRRRR.         //
//            RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR    0RRRRRRRRRRRRRRRRRRRR         //
//           @RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRK     0RRRRRRRRRRRRRRRRRRR~        //
//          [[email protected]     ^RRRRRRRRRRRRRRRRRRR"        //
//          [RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR"      [RRRRRRRRRRRRRRRRRRR/       //
//          [RRRRRRRRRRRRRRRRRRRRRRRRRR"  "RRRRRRRR"""           RRRRRRRRRRRRRRRRRRRRw      //
//          [RRRRRRRRRRRRRRRRRRRRR"\         .                   0RRRRRRRRRRRRRRRRRRRR      //
//           RRRRRRRRRRR ?R^""                                   'TRRRRRRRRRRRRRRRRRRRW     //
//           [RRRRRRRRRR                                            "RRRRRRRRRRRRRRRRR"     //
//            [[email protected]                                              "RRRRRRRRRRRR0RR      //
//             TRRRRRRRR                                ;wmw_           TRRRRRRMTF  [H      //
//              ?RRRRRRRL                      _;[email protected]/          ?RRR"              //
//               '0RRRRRR          _;        [RRRMT"""""?,,               RRw       [email protected]      //
//                 ?RRRRRW      ;#RRRH           [email protected]?"            RRRL       RL     //
//                   TRRRR   ,gRRR?, _           TRRR^?`                 [RRRR~      RR     //
//                     TRR y0R"  [email protected] [                               [RRRRR     [RR"    //
//                       T  " ,#RRR""?"  H                               ARRRRRH    [RRM    //
//                                       "                               RRRRRRR   jRRR"    //
//                        %             [         mWw;_                  RRRRRRR~ 'RRRR     //
//                        [L            r             ""w,               RRRRRRRK  ^0R`     //
//                         [L          ;"                 "w            [RRRRRRRR           //
//                         'Rw        |"            _c___;[email protected]      #RRRRRRRRRH          //
//                          [R.        "g_      ;[email protected] _aRRRRRRRRRRRH          //
//                           [R.       ,RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR           //
//                            0R.     xRRRRRRRRRRRRRRRRRRRF/RRRRRRRRRRRRRRRRRRRR"           //
//                             0Rw,[email protected]"?   #RRRRRRRRRRRRRRRRRRRR"            //
//                              0RRRRRRRRRTTT?"?.      y#RRRRRRRRRRRRRRRRRRRRR              //
//                               TRRRRRRRRRWwwwwwwww#RRRRRRRRRRRRRRRRRRRRRRRL               //
//                                ^RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRM                 //
//                                  TRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR^                   //
//                                   ^%RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRF                     //
//                                     "RRRRRRRRRRRRRRRRRRRRRRRRRRR^"                       //
//                                        "0RRRRRRRRRRRRRRRRRRRRM\                          //
//                                           "RRRRRRRRRRRRRRR"                              //
//                                               ?"TM^T""                                   //
//                                                                                          //
//                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////


contract SDCHK is ERC721Creator {
    constructor() ERC721Creator("Sandchuck", "SDCHK") {}
}