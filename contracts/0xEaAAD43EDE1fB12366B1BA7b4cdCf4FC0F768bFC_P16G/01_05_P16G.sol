// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pepe Sees Everything
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                     //
//                                                                                                                                                     //
//                                                                                                                                                     //
//                                                                                                                                                     //
//                                                                                                                                                     //
//                                                                               .:^~!.J;;;J;SSS;;?.!^:                                                //
//                                                                          :!JSGGBBBGPPPPPSSSSSPGGB###BS.^                                            //
//                                             .::~!!!!!!!~:::.          :?GBBS;J?...................?JSB&&G;!.                                        //
//                                        ^!J;GBBBBBBBBBB######G;?~.   .GBPJ..!...........................JP#@#;!.                                     //
//                                    .!;GBGPSJ??..........???;PG#&#SJB#S???;;SSPSSPGGGPPPSS;;JJ?............JPB&#S~.                                  //
//                                  :[email protected]@@#B##BBGGGPPPSSSSPPPGGBB####BGS?..........?S#@#..                                //
//                             .:~!S&@#PPPGGGPPS;J??.........J;PBBBBGS;JJ??....................??JSG#&#[email protected]#?.                              //
//                       .:!J;PGBBGGPSSS;;SSSPGGB#&##BGSJJSPB#BP;?..!................................JP#&[email protected]^                             //
//                   .~JPGGGS;J?..................?J;[email protected]&#BP;JJJ;;SS;;;;;;;;JJ?????.....................;P;[email protected]&.                            //
//                 !SGGS;???JJJJJJJJJ?...............?J#&PPPPSSS;;;SSSSSSSSPPPPPPPGGGBGPSJ?.............................J#@?                           //
//             .:[email protected]&GPPGGPPPPGGGGGGBBBBBGPSJ?....;GB#GS;JJJ;S;PSPPPPPGGGPPPSS;JJ????J;SPGBBGPSJJJ?......................J&&~                          //
//         ^.JSGSP;J????????JJ??????????JJ;PP?..JBBSJJ;SPPSJ?.~^^^^^^^~~~!.??;SPPBBBGPSJ?..?;SPGPS;[email protected]                          //
//      ^JSPSJ??J;;SPPGPPPPPPPPGGGGBBBGGPS;??..;@G;PGSJ~:.         ..            .:~.JPBBBGP;?............................?#@~                         //
//     .&S..?;PP;J.~^:.  ..        .:^~.JPGB&#P&@BJ!.        ~?SPB####GS?^              :~.;SG#BGGBB;[email protected]                         //
//     P&;PBS?~.    :.?PBBBBBP?:           .^.JG..         [email protected]@@@@@@@@@@@@G~                  :::.^B&J.....................;@G                         //
//     [email protected]:      ~P&@@@@@@@@@@&;.            .B          .&@@@@@@@@@@@@@@@&:                .~JPPPSJ......................?&&..                       //
//     [email protected];       [email protected]@@@@@@@@@@@@@@B^           BG         [email protected]@@@@@#PG&@@@@@@@@?              :J#BP;J..........................#@&#J^                     //
//     ;@:      .#@@@&GSG&@@@@@@@@J          .&S         [email protected]@@@&..  ^#@@@@@@@S            :;#GJ..............................PP?S&@S:                   //
//     [email protected]:      :&@@&^   [email protected]@@@@@@#:          :&#.        [email protected]@@@G   .!&@@@@@@B^          ^S&GJ....................................?S&&?                  //
//     ;@S       [email protected]@@;~:^[email protected]@@@@@G^          .^[email protected]        ^#@@@@#GB&@@@@@@@S.        .!G#GJ..?SPJ..................................J#@;                 //
//     :[email protected]:     :[email protected]@@@@@@@@@@#?       .:!JPBBP#@J.       ^S&@@@@@@@@@&B;^       .!;BGS?!.JS#[email protected]               //
//      .;@&S~:.   ^.SBBB#BPJ~.  .:~.;SGBGSJ?.!J&@#P!:      .^!?J;;J!^:      [email protected]              //
//        :;#@&#GSJ?....???..JSPGGGGPSJ??JJ?.JGBS?;[email protected]&BSJ.~:        ..:^[email protected]S              //
//          [email protected];;SPGBBGBGGPPSS;J???JJSPGGSSPBG;.....##SPG###BBGGPGGGBBGGGPSJ?...?SPGBPJ...............................................?#@;             //
//          .;##PS;JJ??JJ?JJ;;SPGGGGPS;??SBP?.......S#G;?..??JJJ?J???.....??;PGGGP;?............?JJ?...................................?#@!            //
//            .;#@@&GPPPPSPPS;JJ??.....SBG?..........?SB##BGPSSSSSPPSPPPPPPP;J?..!.....??JJ;;SPPS;??....................................;@B.           //
//               ?&@&GS;?...!........JB#J...............?J;;SSP#@@@@BGGPPSSS;[email protected]?           //
//              !BB;;PB###BGGPPSSSPSP#S.........................?JSPPPGGPGGGPPSSS;;JJ???........................JSPGBG;[email protected]           //
//            .S&S......?J;[email protected]#?..................................................................??JJJJ?....?JP&[email protected]           //
//            [email protected].................??J;SPGGBBBBB####PJ....?#[email protected]           //
//          [email protected];.................P#?....................................................??;;SPG###BBGPPSSSS;;SPG&&B;...;@[email protected]           //
//       :JG#@@S?................SJ..............................................?J;SPGBBBBBGPSSSS;;;;;;;SSSS;;;;[email protected]@J..?;[email protected]           //
//      .B&PSPG##GGP;?.................................................???J;;PGGBBBBGPPSS;;;;;;;;;;;;;SS;;S;;SSS;[email protected]@S            //
//      [email protected];;;;SSPGB###BPSJJ???..........................???JJJ;;SSPGBBBBBBBGGPPSS;;;;;;;;;;;;;;SSSPBB##&P;SSSS;S&&?....................#B.            //
//      ^#@GS;;;;;;;SSPGGBB####BBBBGGGPPPSSSS;;SSPPGGGBBB#######BBGGPPSSSS;;;;;;;;;;;;;;;;SSPPGBBBGSJ?JB&P;S;S;;#&[email protected]~             //
//       :;&&#GSS;;;;;;;;;;;SSSSSPPPGGGGGGBBBBBGGGPPPPSSSSSSS;;;;;;;;;;;;;;;;;;;;SSPPGGBBBBGGP;J.!!!?P#BS;SS;;P#BJ....................;@;              //
//         :.SB#&#BGPSS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;SSSSPGGBB#BBBPS;;J?.!!!!!!.SGBGS;SS;;SB#S.....................;@S.              //
//             :~.JP&@###BGGPSSSSS;;;;;;;;;;;;;;;;;S;SSSSSSSPPPPGGGBBBBBBBGPPS;J?.!!!!!!!!!!!!?SGBBS;;;S;;SB#[email protected]?                //
//                :P#GSPPGGG#@&######BBBBBBBGGGBBBB##BB#BBBBGGGPSSS;;J?..!!!!!!!...?????..?;GB#GSS;;;;;;SG#G?.....................?B&!                 //
//               ;&GS;;;;;SB#BPPPPPGGGGGGGGG#@#G;J???.....!!!!!!!!!!!!!!!.?;SPGB##B###&@&#BBPS;;;;S;;;PB#G?......................S&P:                  //
//             [email protected];;SS;SB#GPSPPPPPPPPPPPPSB#J!!!!!!!!!!!!!!!!!!!!!!!?;GB##BBGPPPPGB##BGPS;;;;SS;;;SG#GSJ......................?B&?                    //
//             [email protected];SSS;S#&[email protected];~!!!!!!!!!!!!!!!!!!!?;PB#BGPPSPPGBB#BBGPS;;;;;S;;;;SPGBGJ........................P&P:                     //
//            ^@#;;S;S;[email protected]@G!!!!!!!!!!!!!!!!?;PB#BGPPPPGB##BBGPS;;;;;S;;;;;SPGBBPJ?........................S#G!                       //
//            [email protected];;;;;;P&&#[email protected];.!!!!!!!!.?;PB&#BGGGB###BBGPSS;;;;;;;;;;;SPGB#GSJ?........................?P#G!                         //
//            [email protected]#;;;SSS;SPGB########BBBBGGGGG&@&#GGGBB##&@@@@&####BGPSS;;;;;;;;;;;;SPGBBBGSJ?..........................;G#G~                           //
//             [email protected];;;SSS;;;;;;SSSPPGGGBBBBB##########BBBGGPPSSSS;;;;;;;;;;;SSSPGBB##GP;?............................JSBBJ^                             //
//             :[email protected]#P;;;;;;;SS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;SSPPGGB###BBGP;J?.............................JPBB;~                                //
//              .J#@&GPSSS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;SSSPGGGB#B#BBGSSJ??.................................JPBB;~.                                  //
//                .!SB##&&##BBBBGGGGGGPGGPGGGPPGGGGGGGGBBBBBBBGPS;J??.....................................?;G#G;~.                                     //
//                    .:^~!?JSSG&@@@BGPPGGGGGGPPGGGPPSS;JJ?...........................................?;PB#GJ^                                         //
//                              :!JG##BP;J?.!!...................................................?JSGB#GJ!:                                            //
//                                  .^.;G##BGP;?..........................................??JSPB#BBS?!:                                                //
//                                       .:!JPGBBBGPPP;;;JJJJJJJJJJJJJJ???JJJJ;;J;;;SPPGBBBBGSJ.^.                                                     //
//                                             .^~.J;SSPPGGGGGGGGBGGBBBBBGGBBGPPPGPS;;??.~:.                                                           //
//                                                                   .....                                                                             //
//                                                                                                                                                     //
//                                                                                                                                                     //
//                                                                                                                                                     //
//                                                                                                                                                     //
//                                                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract P16G is ERC1155Creator {
    constructor() ERC1155Creator("Pepe Sees Everything", "P16G") {}
}