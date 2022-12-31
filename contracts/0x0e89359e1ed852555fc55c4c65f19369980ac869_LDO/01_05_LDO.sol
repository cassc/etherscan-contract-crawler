// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LASTDAYOF
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                       //
//                                                                                                                       //
//    S.       .S_SSSs      sSSs  sdSS_SSSSSSbs         .S_sSSs     .S_SSSs     .S S.           sSSs_sSSs      sSSs      //
//    SS.     .SS~SSSSS    d%%SP  YSSS~S%SSSSSP        .SS~YS%%b   .SS~SSSSS   .SS SS.         d%%SP~YS%%b    d%%SP      //
//    S%S     S%S   SSSS  d%S'         S%S             S%S   `S%b  S%S   SSSS  S%S S%S        d%S'     `S%b  d%S'        //
//    S%S     S%S    S%S  S%|          S%S             S%S    S%S  S%S    S%S  S%S S%S        S%S       S%S  S%S         //
//    S&S     S%S SSSS%S  S&S          S&S             S%S    S&S  S%S SSSS%S  S%S S%S        S&S       S&S  S&S         //
//    S&S     S&S  SSS%S  Y&Ss         S&S             S&S    S&S  S&S  SSS%S   SS SS         S&S       S&S  S&S_Ss      //
//    S&S     S&S    S&S  `S&&S        S&S             S&S    S&S  S&S    S&S    S S          S&S       S&S  S&S~SP      //
//    S&S     S&S    S&S    `S*S       S&S             S&S    S&S  S&S    S&S    SSS          S&S       S&S  S&S         //
//    S*b     S*S    S&S     l*S       S*S             S*S    d*S  S*S    S&S    S*S          S*b       d*S  S*b         //
//    S*S.    S*S    S*S    .S*P       S*S             S*S   .S*S  S*S    S*S    S*S          S*S.     .S*S  S*S         //
//     SSSbs  S*S    S*S  sSS*S        S*S             S*S_sdSSS   S*S    S*S    S*S           SSSbs_sdSSS   S*S         //
//      YSSP  SSS    S*S  YSS'         S*S             SSS~YSSY    SSS    S*S    S*S            YSSP~YSSY    S*S         //
//                   SP                SP                                 SP     SP                          SP          //
//                   Y                 Y                                  Y      Y                           Y           //
//                                                                                                                       //
//                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LDO is ERC721Creator {
    constructor() ERC721Creator("LASTDAYOF", "LDO") {}
}