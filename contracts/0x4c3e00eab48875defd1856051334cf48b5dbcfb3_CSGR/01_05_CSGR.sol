// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CryptoStinger
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                      //
//                                                                                                                      //
//                                                               HG                                                     //
//                                                               3iX                                                    //
//                                                               SSis                                                   //
//                                                              sGhsrs                                                  //
//                                                 rrrrsH9&&3 AiShASSS&                                                 //
//                                                5rrrrBASsrS&hSSA&hhG&                                                 //
//                                                 ssshGh2SriXGiih3hrhhB                                                //
//                                           G  A  Gi9539&BA SSssi&Ah9&B                                                //
//                                           hS AH  hG      5BSGsSSSSM&&                                                //
//                                          5G3 SMBMH&     ShiSGs&&SSHBB                                                //
//                               iS       &2iisXrrMA&AH    Sss5S#GGASGSA                                                //
//                             GiiHrs    hirrrrrrrrsiris  MrAhSr995XB&X&                              H&SS92SiS529B     //
//                             sr59SsssSSGSirsirrrrrrrsihr:SMrrBXrG2hBH&                       #hS2rX&&h9rGsrrrr&&A     //
//                            3s5HhSss5sr9GisSsrrSrrrrrr,,,iSs3X52rrMGXX                   Gh&92Hrr2GAMAA5Mr3irrr5M     //
//                   G  hh rsr:9AiSsisi&i9shiSssssrrrrsSr,rS5S5hAXrhr2A                G&9X3GhGisSsrr2A&M&AiAi9XHA      //
//                   3 X&X3&SHGHH&SssSS5X&A23ssS25AisrsSi,srri9&5A3A3Gr            h&A3GG33XH33AAGG99ABH32MiMM5GG&      //
//                   hr&hhhXG23rHh&Sssi95siSisSS3S52s2S3SirssrGHHh  SMS        H3&3hB&&rBh&hGhHMH9rAHAAhAAGhG3Hr9       //
//                    h&rrsh5 i.,G9H9ssssrsrSi5&GhGhhA2SSSs3sMiiG    9#     hGA&&&&h29A&A3rBHh&HSSG3A3H&3G&BHMS9M       //
//                hH9&h23#r2Srr,.3GhGrishssssssH&B&Ah;XSXM&.hrAh&    A  M&9&HBBH9G&GhGAHXirAHA335229hA9BXXs32GG#        //
//                   AHA299r#3rMr3G9Sir.;:.,hGBh&&&GSGXHsi5;25X3S3GG&&&GG93GGHhB&M&&hBHMG2AGA&3h3Brrrrrr5GSh22M         //
//                    GH99&HrA9XGGH3SSi&S;;r,,,,,i9;5s5SXr;hX&HrBGXi29G&BA&&H&5&&9XhGGGiSX2BBA39G2rG3H&3AH9Si           //
//                   G5H3H5S5&GGS33BABHhGiS.  .r,rrrr,,,,,:rG9i2iHh399&H9hXHH9&&Gs3hHrGrAr9rhA2rrr3sAHrrH3rH            //
//                   MS&&HGG3rG9HMA&BBAB&HBBMB,rXrrrS,,,,,:::&Gr2iGAhGBMMG3BAA&BBHM93rG&2srr5AHis39G&H93SAM             //
//                   2rHh5Hr5sG2rhHHH&BBHMAHHH&ArSrGA;H;:r2ssrS3Ai9A&H&3&XHAAMA&MGrAH3irs355M3rirs5hArrGh               //
//                   r3h2H9hMr99MHr&BBAHHHBGMHBhA&isiiAMB3isrrsihSHssGG9hHBHAA9r25hr32r2rXhh9HGhsB5s&rGB                //
//                   &B       rGAr&A&BHBHBAAhMB3iii59GrSiSSSsrs3hrh&&&Mh9&A&HXGA&A&r992&h5rBHAHXriGrrh                  //
//                   3H     9hSr&BBBBGBAsrs92rBisssiisrrrA33SrsAG&&92AH&3sHGAGAG&&9rr52sHHGH&i923rrhM                   //
//                   BA   &23XX3HHHBBMH9rrrr:rHBssSissrrrr3Sisih&GH&G3sGrrhG&&&5A3rrriX3223hs&&r3X3                     //
//                        3&rhrAs2MMBXr;r.rrrr,,s3SMGisssiBA&h9GG3S3hGSG5G2AGG3H3rsrr3h359AHA&rr2                       //
//                        &99G&hABMMHBrrr.r.,r,,;HhHHSrHBHH&h3X&9&9Xs&&r9GrrhhAGh5srr3rGrr3As99                         //
//     #3AG&BB             GH99XGiBABHAMMMMXHH3BBHisrrrGSS;BAHGrGrr2r9&&A&hr&rXX5rHr33rGhHMhh#                          //
//      rhBHHBAAG           &G3rsrBBBBHMBMMBBBHssssMsrs33&h&AA3&GGrr&MA33GrhrrrHX35XrrB9hhh                             //
//     B3HHHB&AHGHG        #3HGBABMBrHA&BHMrABMiSSii3Sih3H&B&9G&939HHHGr2rASrhXh9hH&rr9GG                               //
//     BBGHHAH&&AHGAMBArrBHrG3B9&AABHHHBBHBB&HMsiSSsri9MBGBBAAAHX&&hH&&GGAH&2hAh5AA&hGH                                 //
//     HABHMM&G&HA&HHMhrrG2rBrr&&rhB9HB&BBMBA9HMX2siS&HBSABHH&B2M3s9G&XAhM&h&&HHSGhB                                    //
//     &9MhM&HHG2ABBHMHAMAArrrrrrSsMBBBBBB9HAMBMASiSihBB5H392AM3sBGrr&XG293&h&&B                                        //
//     &HBMhMA9MBHMMMBHMr, ASrrrABhM  MMHH&ABBHMGXii3XA&riBAHHAMrrrrX293                                                //
//        &AMMMMMBHHH&B3H&             MABAMMBBMMHsiSBAiGB2SGAGShS5ssr2                                                 //
//              # #                     rHBMMMBHBHMih&&Hh3HH9ihAA22hhB                                                  //
//                                      MhBBMAHBBBGr&HA5irrrrrHh&2i3                                                    //
//                                       MBBBB&HBBHBBBBrrhSAM9X999                                                      //
//                                       HMMBMBB        HHr59AM&                                                        //
//                                        ABBh            9XAh                                                          //
//                                         #BB             93h                                                          //
//                                          M              HH&                                                          //
//                                                          &                                                           //
//                                                                                                                      //
//                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CSGR is ERC721Creator {
    constructor() ERC721Creator("CryptoStinger", "CSGR") {}
}