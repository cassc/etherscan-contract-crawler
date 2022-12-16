// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AlinaLanue
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                9M9,:32i                                                                              //
//                         r&H##@#@@###BHA3,                                                                            //
//                    ;hB#B###@@@@@@@@@@#####MA;                                                                        //
//                  iHH##M##@@@@@@@@@@@@@@MMMMM#MBG                                                                     //
//                [email protected]###@@@@@@@@@@@@@@@##MMM#####M5                                                                  //
//               iAMBBB##M#@@@@@@@@@@@@@@@##M####@@###M5r2                                                              //
//              sBBBBBH##[email protected]@@@@@@@#3         .SHM##@@##MMG3                                                             //
//              h3MGMBM####@@@@#A.                 &#[email protected]#MMB3r;                                                         //
//            .22&MMBBB##@@@@#X                   5B   3##MMMMAX.                                                       //
//            5MXM#H9#B##@@@#i                    &     3#@#MMMMMM2S:                                                   //
//            M&[email protected]##@@@#.                    ;     :##@##MBHBMHMM#M&                                                //
//           2h#&[email protected]####@@@#r                          SM  G,  rB9&###@@#BB                                              //
//           MMMBB#@@#@@@#9                        .  ##S.       MM#@@@##B#                                             //
//           #AABHM##@@@#&                         , .             B##@@@@M2                                            //
//           MAAGBM#####H5                                          [email protected]##@@#M                                            //
//           ,MMhG9M####M.                i                           ###@##                                            //
//            [email protected]@#XBM###B,               9                   i        ,[email protected]##9                                           //
//             B#@@@###@Ms             ,                     i         [email protected]@#M                                           //
//            .H######@#M9            ;       5s           B       rX:  ;##@B,B                                         //
//          hHAGMM#@@@@@#9                  #             5      .2&h;. :G##HrM                                         //
//        BB9  [email protected]@@@##Mhr          ,     #@#                   5 :  .;sMH#hh#                                         //
//       MB   [email protected]###H9XA.              Ms:                   S     .  ,[email protected]                                        //
//       Ah   [email protected]#M#&3BMBS,             M.                   ;,.         [email protected]#B9                                      //
//       G   MH#M##MH5&MBHB&9;                                 B.           ##@##h9X                                    //
//          3AMMB##MG&MH&##MM3S;                              &S            [email protected]@##AAMBH                                  //
//          BBM&B##Hh#[email protected]@#BA&BS                            .              #@@@MMBM#MM                                 //
//         iGABMMM#3B#3A#@@MBM3MBS:                                        [email protected]@@@M###@#5h                                //
//         9hBBM#[email protected]@##BHG##A2                                      @@@@@@MB#@@#H2                                //
//         S59AM#H&A#[email protected]###[email protected]@#3&                                 [email protected]@@@@@@@[email protected]@#Ms                                //
//         ;&3hMMHBBMAG&[email protected]@#@#BB5##@#B&3r                            XG#@@@@@@@@#####Hhr                                //
//         :9H;BAHBMMA&[email protected]@@##MMHA##@##GG2:                        [email protected]@@@@@@@@@##G2X                                 //
//         rGA 3HhH&MA2G&@@@#@###XB#@#BMBH2                     :2i    s#######@@@MX5Sr.                                //
//          GB:rMABX&&[email protected]@@M#[email protected]#MMM####MrB     hr            ii.       3#M##M####AhhB9,                                //
//          iM GG&B&BGB&&##@[email protected]#@#MMM#####MHA.  i    ,:ri::::           XHMM2B####hMMMB .                               //
//             HGhB&BHMHM#@#H#[email protected]@###M######MHBhhG9X                     X3M23A###BH###B . r                             //
//             2GA&BMBMM###@H#[email protected]@@@####M#MM####HhhMBH                   [email protected]@#HMM###MA  s. i399iiX3                   //
//              .hG&MHMA###@M#[email protected]@@@@##@##MMGSiBM#MM###MG:              [email protected]@#MH#MM#MB&s &hh52X5S5S5X                  //
//                BBMMMM###@[email protected]@@@@#######Bh2AM##B##HABMB            ;2M&M#MHBh##M##MAS. :52S2335S23X                 //
//                &M##MMMM####M#@@@@@####BAGBMMMMM#@#@&s 22B.           rh#MGXB#M###M#MHA5   G5XX22iSri2                //
//                MM##HMHM#H#M##@@@@@[email protected]@@##GBMBM###@@@H  ,XX            3MGXH#######BBGGS:   2iX5SX33933               //
//                MMM#MM&[email protected]#M#[email protected]@@@@@@@@@@#@BHMM#[email protected]@@@@@M99&            s&hMBB#####MBX92h532 ,22h22AAAA3               //
//                HMB#[email protected]#M#[email protected]@@@@##@@@#@@S iM##M3###@#M##r           iGAMMAM#MhMMMA5X932H93iHMMB&hAh9.              //
//                ABB#&[email protected]#H#[email protected]@@@@@@@@@@#X;AA##    B####HGr;,         55i25&BMMGAMBAG9&h&9BHH##MMMMM#&2              //
//                HGM#MHh#@M#[email protected]@@@@@@@@#@@X92Hi,      3s;,,.r,         Si.,  2hBMB&9M#HB&&&BMBMHM#MHHHAGM              //
//               sA9MM9A9#@[email protected]#@@@@@@@@#9h&S          :                i;.  S&BMMMMMM#M#MHAMMB#MM#MBHAXA5             //
//               ,[email protected]##@[email protected]@@@@@@#Gh3AS            : ..    .        .:    GBHHHMMMMHMBHMM&BMMM###MBh&             //
//            GB :[email protected]@[email protected]@@@@@@M9S              .   .     .         .,  :hSSi3ABH&HBGAM&MBM####@#HX             //
//           2M5,iXHMMAA&[email protected]#G#@@@@@@92                ,.                   s.SH,..;33A9H3GHBB###M##@##H2             //
//         :H9S; S3M#HH&[email protected]##@@@@@#[email protected]                    .;  ,            . :#H,  :52AB&H#[email protected]@@@####M3r             //
//         2MH , ,3BBAHBHA#[email protected]@@@@@#@@                        ,.             ; H#S    :[email protected]#@@@@######H.            //
//        r2MMsi,GABBMAMhh#XAMG#@@@@#@@                           s5           X  h#A    sMAMM#@@@@@##G23Mhi            //
//        i.BH5 shHG5AH3hM#9&[email protected]@@@@@@,                            2,          ; r  G#r    MH###@###MM&3h9&             //
//          MHX ;[email protected]@@@@@@#                          .  39                 2;   M&B####M&9HBBBBB2           //
//         B##9S:MMhGG&3G#&3MB#@@@@@@@@                           :  G:                   i. B2B##M#Ms9BBBMMMS          //
//          HBM&XBHHA&&XB#&[email protected]@@@@@##@                           A   X,                    5 r,5HBMBBH32BM&BGX         //
//            #AMMMBMMh&B#&####@@@@@##@r                          2B .h.                     S2.rXXGBMMMA3A9GAh3        //
//              MHMMM#&HM#M###@@@@##[email protected]                           #. r:                      :;2r2SX&GMMM2ABHH35       //
//               ####[email protected]#####@@@@##[email protected]@                            &  i                       95hh5S:iG5G#hG#M&3       //
//               h##@[email protected]#@@##@@@@#[email protected]@;                        2i B  ;                        &ihX2SSss9rH3H#MG       //
//                #@HMG#@#@@@#@@@@#M.M#r                          s3;.                            5SS:;:..Ss9H&#B       //
//                @#H&[email protected]@@@@##@@@@## B                           . ,i.;.                           55r:, ..,SBHBM       //
//               ###BM#@@@@@@@#@@@[email protected],G                            :rA r                              SS.... :XMMM       //
//               M##B#@@@@@@@##@@@##,&                           ,,5S..                            ,  2,. , ,:X##       //
//              ;A#M&#@@@@@@@#M#@@@@5H#                          ,,:&:,.                           ;  B5 ..  ;s#B       //
//            ;:,2B&##@##@##@###@@[email protected]@#@                         ,r&Sr.                            ;  2s,.. ,SM        //
//           is,,;2A#@5#BB#######@#Mi&[email protected]@#r                       .:2S,                            .   s;;   ;B3        //
//          ss:, i5&M#MMh.hMMMHH###59MM#@A;                      ,.i35 ,,           LANUE          .  s..,. .i&:        //
//          25,, :59h## 2:X&[email protected]@:;#H#@@X                      , ;sh.:                              ;.:.,.,3;         //
//         5s;,   ir9M# A [email protected]@# X###@@@                       ,:;B,.                         .    ,   .;hs          //
//        55X ,   :,GMM:M,5&@M,53#Hs#M##@@@                       .,iB,.                         .   .,.,,rhG           //
//        5X;      ,SM# M2hh## 3 M,[email protected]##@@#,                      .:rM;.                        :,   :r,;iAh            //
//        BS       r.&M MrA3#@33 M;@@B##@@##                      :i5#iSsr                    .:;,:. ;;:3BB             //
//         .       ;:HM [email protected]#92:9#@@[email protected]#@@@#                      ,s2#2s:;                   ,r;r5i  :,&MH              //
//                ;,S# &39XH#BSGrG#@@[email protected]@@@@#                     ..:S#X;i:r              ...,rssii  i:A#                //
//            .  : .9M,5,,5#M2r3SB#@#[email protected]@@@@@#                      ;SM&;r::        :sr .,.:ri:      ,5                  //
//            ,: ,r.H B,2&BMM r22M#@M##@@@@@#                     :;SHMs;:.   r2XX5s;s;.;ir:       :3                   //
//                :GXSGAAMM#3,5;9M##M#@@@@@M2                    s irsMG9HHBHHhA3h23X32SS.        .                     //
//               .235MB#MM##S3isBM####@#M##ABB                    ,:[email protected]#AH&GAAGGG&9X2s.                                 //
//                Xr#AM##@#H99:9HMMs##@##M#BHB;                   ::2X##&h93X59Ss:,...                                  //
//                 rMM##@@#BMXXMBMBH##@##B#M3MM                  .;SSiH#H5SSS2Sis; ,.,                                  //
//                   @##@@#MBMBMM#r#####AB#MB#A                   ;;[email protected]#MMAA&&A2s;;:;:.                                //
//                      :#M#BM#@@G###@##MXHHM#H                 rr ; ;s5r,B#MM###A3X53                                  //
//                           [email protected]@MH#@#@##MMBGMM2                 ,      r9      [email protected]                                     //
//                               M#@@@@@MMA2#                   ,,   ,                                                  //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LANUE is ERC721Creator {
    constructor() ERC721Creator("AlinaLanue", "LANUE") {}
}