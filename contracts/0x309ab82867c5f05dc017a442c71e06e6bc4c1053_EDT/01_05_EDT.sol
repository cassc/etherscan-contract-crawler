// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LePro • Editions
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    S.        sSSs   .S_sSSs     .S_sSSs      sSSs_sSSs                                 //
//    SS.      d%%SP  .SS~YS%%b   .SS~YS%%b    d%%SP~YS%%b                                //
//    S%S     d%S'    S%S   `S%b  S%S   `S%b  d%S'     `S%b                               //
//    S%S     S%S     S%S    S%S  S%S    S%S  S%S       S%S                               //
//    S&S     S&S     S%S    d*S  S%S    d*S  S&S       S&S                               //
//    S&S     S&S_Ss  S&S   .S*S  S&S   .S*S  S&S       S&S                               //
//    S&S     S&S~SP  S&S_sdSSS   S&S_sdSSS   S&S       S&S                               //
//    S&S     S&S     S&S~YSSY    S&S~YSY%b   S&S       S&S                               //
//    S*b     S*b     S*S         S*S   `S%b  S*b       d*S                               //
//    S*S.    S*S.    S*S         S*S    S%S  S*S.     .S*S                               //
//     SSSbs   SSSbs  S*S         S*S    S&S   SSSbs_sdSSS                                //
//      YSSP    YSSP  S*S         S*S    SSS    YSSP~YSSY                                 //
//                    SP          SP                                                      //
//                    Y           Y                                                       //
//                                                                                        //
//      sSSs   .S_sSSs     .S  sdSS_SSSSSSbs   .S    sSSs_sSSs     .S_sSSs      sSSs      //
//     d%%SP  .SS~YS%%b   .SS  YSSS~S%SSSSSP  .SS   d%%SP~YS%%b   .SS~YS%%b    d%%SP      //
//    d%S'    S%S   `S%b  S%S       S%S       S%S  d%S'     `S%b  S%S   `S%b  d%S'        //
//    S%S     S%S    S%S  S%S       S%S       S%S  S%S       S%S  S%S    S%S  S%|         //
//    S&S     S%S    S&S  S&S       S&S       S&S  S&S       S&S  S%S    S&S  S&S         //
//    S&S_Ss  S&S    S&S  S&S       S&S       S&S  S&S       S&S  S&S    S&S  Y&Ss        //
//    S&S~SP  S&S    S&S  S&S       S&S       S&S  S&S       S&S  S&S    S&S  `S&&S       //
//    S&S     S&S    S&S  S&S       S&S       S&S  S&S       S&S  S&S    S&S    `S*S      //
//    S*b     S*S    d*S  S*S       S*S       S*S  S*b       d*S  S*S    S*S     l*S      //
//    S*S.    S*S   .S*S  S*S       S*S       S*S  S*S.     .S*S  S*S    S*S    .S*P      //
//     SSSbs  S*S_sdSSS   S*S       S*S       S*S   SSSbs_sdSSS   S*S    S*S  sSS*S       //
//      YSSP  SSS~YSSY    S*S       S*S       S*S    YSSP~YSSY    S*S    SSS  YSS'        //
//                        SP        SP        SP                  SP                      //
//                        Y         Y         Y                   Y                       //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract EDT is ERC721Creator {
    constructor() ERC721Creator(unicode"LePro • Editions", "EDT") {}
}