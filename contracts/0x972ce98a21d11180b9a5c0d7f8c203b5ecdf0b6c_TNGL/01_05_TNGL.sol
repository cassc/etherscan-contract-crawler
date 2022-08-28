// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Tangleverse
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////
//                                                                                   //
//                                                                                   //
//    ___________.__             ___________                     .__                 //
//    \__    ___/|  |__   ____   \__    ___/____    ____    ____ |  |   ____         //
//      |    |   |  |  \_/ __ \    |    |  \__  \  /    \  / ___\|  | _/ __ \        //
//      |    |   |   Y  \  ___/    |    |   / __ \|   |  \/ /_/  >  |_\  ___/        //
//      |____|   |___|  /\___  >   |____|  (____  /___|  /\___  /|____/\___  >       //
//                    \/     \/                 \/     \//_____/           \/        //
//                                                                                   //
//    #_                                                                       d     //
//     ##_                                                                     d#    //
//     NN#p                                                                  j0NN    //
//     40NNh_                                                              _gN#B0    //
//     [email protected]_                                                          [email protected]    //
//     [email protected]_                                                      [email protected]_L    //
//     _F`@[email protected]_                                                [email protected]#p"Fj_    //
//     "0^#-LJ_9"NNNMp__                                         _gN#@#"R_#[email protected]^9"    //
//     a0,[email protected]@0NMp__                                __ggNZNrNM"P_f_f_E,0a    //
//      j  L 6 9""Q"#^[email protected]____                ____gggNNW#W4p^[email protected]"P"]"j  F     //
//     rNrr4r*[email protected]@[email protected]@[email protected]@N#@[email protected]@#@4p*@[email protected]@[email protected]@[email protected]#[email protected]    //
//       F Jp 9__b__M,Juw*w*^#^9#""EED*[email protected]@^[email protected]*#EjP"5M"[email protected]*Ww&,jL_J__f  F j      //
//     -r#^^0""E" 6  q  [email protected]""*,_Z*q_"^pwr""p*[email protected]""0N-qdL_p" p  J" 3""5^^0r-    //
//       t  J  __,Jb--N""",  *_s0M`""[email protected]__JP^u_p"""p4a,p" _F""V--wL,_F_ F  #      //
//     _,Jp*^#""9   L  5_a*N"""q__INr" "q_e^"*,p^""qME_ y"""p6u,f  j'  f "N^--LL_    //
//        L  ]   k,[email protected]#"""_  "_a*^E   ba-" ^qj-""^pe"  J^-u_f  _f "[email protected],j   f  jL      //
//        #_,[email protected]^""p  `_ _jp-""q  _Dw^" ^cj*""*,j^  "p#_  y""^wE_ _F   F"^qN,_j       //
//     w*^0   4   9__sAF" `L  _Dr"  m__m""q__a^"m__*  "qA_  j" ""Au__f   J   0^--    //
//        ]   J_,x-E   3_  jN^" `u _w^*_  _RR_  _J^w_ j"  "pL_  f   7^-L_F   #       //
//        jLs*^6   `_  _&*"  q  _,NF   "wp"  "*g"   _NL_  p  "-d_   F   ]"*u_F       //
//     ,x-"F   ]    Ax^" q    hp"  `u jM""u  a^ ^, j"  "*g_   p  ^mg_   D.H. 1       //
//                                                                                   //
//                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////


contract TNGL is ERC721Creator {
    constructor() ERC721Creator("The Tangleverse", "TNGL") {}
}