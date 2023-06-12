// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Russian Girls by Krisbow
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                      //
//                                                                                                                      //
//     ______                      _                   ______  _         _                                              //
//    (_____ \                    (_)                 / _____)(_)       | |                                             //
//     _____) ) _   _   ___   ___  _   ____  ____    | /  ___  _   ____ | |  ___                                        //
//    (_____ ( | | | | /___) /___)| | / _  ||  _ \   | | (___)| | / ___)| | /___)                                       //
//          | || |_| ||___ ||___ || |( ( | || | | |  | \____/|| || |    | ||___ |                                       //
//          |_| \____|(___/ (___/ |_| \_||_||_| |_|   \_____/ |_||_|    |_|(___/                                        //
//                                                                                                                      //
//     _                                                                                                                //
//    | |                                                                                                               //
//    | | _   _   _                                                                                                     //
//    | || \ | | | |                                                                                                    //
//    | |_) )| |_| |                                                                                                    //
//    |____/  \__  |                                                                                                    //
//           (____/                                                                                                     //
//     _    _         _        _                                                                                        //
//    | |  / )       (_)      | |                                                                                       //
//    | | / /   ____  _   ___ | | _    ___   _ _ _                                                                      //
//    | |< <   / ___)| | /___)| || \  / _ \ | | | |                                                                     //
//    | | \ \ | |    | ||___ || |_) )| |_| || | | |                                                                     //
//    |_|  \_)|_|    |_|(___/ |____/  \___/  \____|                                                                     //
//                                                 i  2:                                                                //
//                                                      :535s.                                                         //
//                                                    :i9HGG&M5 9i:                                                     //
//                                                :s 9G9B      HA93 i:                                                  //
//                                             :iX GBAA&G G.s  MAAAB9, i:                                               //
//                                           ;5  AAAA&Ghhh9 ; hhhG&AAAM&s5;                                             //
//                                         ;5 :MAA2GGhhh  SShM   h2hSGAAA99Xr                                           //
//                                       :S3SMAA&GsGhhA   G2 r#h  9hShhh&A&9,5:                                         //
//                                      r3 9AA&G9GhhX99999 [email protected] 9999X2hhXhhAA# 9r                                        //
//                                     s39MA9 sGBhXhh99, 999999 2 95SSi99h  AA9 s                                       //
//                                    s39AAA&  Ghhh99H   s   h      ii,sGs9 HAAM2i                                      //
//                                   r3 3A&Bs&GG5Xhhh9,;  Mi,h5   ,GMisssshHsG&9B s                                     //
//                                  :X,AA&&&GBXBh3HhXrshhhh  9hhhhsrhhBrG&[email protected]                                    //
//                                  S AA3   53 3hhhSG&AAMh9#M#52H&Gh5hSs&rXA   i#A&X,                                   //
//                                 ;99AA&&M  29GGGGhA;2SrH&BM92r;:s#&XShssM; 9GG&AAHi                                   //
//                                 iBBAS&X  AH&G&AHrhiH:3XB#&33i;rrGAAhhhiAi& XMGAA9 .                                  //
//                                 SHHASHrM&G&HGBS;XH:H;;[email protected]#H:rG5hhs& ;GiihS3GHHB ,                                  //
//                                .S5HAi&3&&&&MhHr9Xhs#25ir;;;sSG;5hGX9S3hASSS&MGGHBM;                                  //
//                                .SBHA&AA&&&&AHiGGX5:5ir;;:::::rr:9h22GX&2i55sXGGHM3r                                  //
//                                 i.AHA5&r&r&HMG33X:Srr;;::,,: ::;2X959h&&hhX3G&&H&3s                                  //
//                                 s:BAAh&  &AHS5352Sir;;:::,,,  :::32h5&&&GBHhGhHH&3;                                  //
//                                 : 9HH9&.H.AHGhX2&MMMHXi;::;;S9BB:X5253h&   &&A2MAS                                   //
//                                  i AHH9&&&AGh9,2h,,sii52iir55553sr:55h&A &&&HHA95:                                   //
//                                  ,5 GHHAAAHh3h25S33393353sS5i399ii52SiAHhA&5HMS ;                                    //
//                                   ,i &HHHAM,3:,si9rssrr29i533;33siiShsAMHHHH#Mi;                                     //
//                                     r35H#GH G::siS3i9iii5S5siiiisisirs3HAhH  5:                                      //
//                                      .r5Gh &&:;si5iiiii5isirsiSrs iSr; hhs32r                                        //
//                                         3hHA&;rXi55ir;r3h r5:;:s;irrr;AG3 :                                          //
//                                         ,,AAH;;XSiiisrr;:;,:::;rs;ii2SAh3A                                           //
//                                         .S3&GsiG3:srr;5X25SiB::;:MX5353G3r                                           //
//                                          [email protected]#Xsrrr5s2,,:::MMhs92339r                                           //
//                                          ;3&9A;25SH#hirrr,.,:;@MMX9sh3X9ri                                           //
//                                          :[email protected];r3r;@MMMsX&AX;h2.                                          //
//                                          ,2539hh9XMBGXisrr;;rsBA#@hGMG9993;                                          //
//                                          ;323h&2iGS,  sr;rr;, s#BH#A2&&9s2S                                          //
//                                         :53GXA5253XsG.        h MM#HhGHhGh9;                                         //
//                                      .,rX3G3XGiXX33X.A  h    M     XH&&&&h&X;                                        //
//                                  :i39    GS&2hAX2X3HH                &   &&    i:                                    //
//                                 :2     :&s;2Gs9XGX3X3               G&           s                                   //
//                                 ;3    :;;:G2iiXX35XS                #A.          S.                                  //
//                                 ;3   :r2:iXiXX3;22iG:               [email protected]          i                                   //
//                                 s3   h3:;XSh5;sXs;2                 [email protected]          2,                                  //
//                                .5    A:rSih;s;;;H933.X3 r 3 s 3 ;   [email protected]           3i                                  //
//                                s     :ssAGsr3;9;9&G9X5SiissssssiiS#M39            2,                                 //
//                               .5    ri2Xh5hi2h3X2&Gh99333333333SsiiS5X&h          2,                                 //
//                                i     5ABr&95h99hGG93XX222X22XXXX3333333A          i                                  //
//                                :X     B2X&52h&3Ahh2555555555555555XX333&@        X:                                  //
//                                 s3     sh;Xh9G&H&39X2222522225555552X339&H       i                                   //
//                                 i        GX:h9GX2&G3933323X5XX2222222X39G&       5,                                  //
//                                ;9       h&Hshs::GhGAG9G9999X3323X2XXXX39GG        s                                  //
//                               .S        ;&HHh2GX;G55r&hhh99999393333339hGB         ,                                 //
//                               .S         @HHH2X3:595HA&G&GhGhhhhhhhhhhhhG#         ,                                 //
//                                r3         &H3235G3HHHHHHAG&GGGGGGGGGGGGG#         S.                                 //
//                                 i        ..3h32SHAHHHHHHHHHAAA&&&&&&G&&h          :                                  //
//                                  :;       S:2GhXHHHHHHHHHHHHAA&&&&&BB           .                                    //
//                                            ,::                                                                       //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract KB is ERC721Creator {
    constructor() ERC721Creator("Russian Girls by Krisbow", "KB") {}
}