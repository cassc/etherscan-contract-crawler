// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Solo historias muertas quedan
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                              //
//                                                                                                                                                                                                              //
//      sSSs    sSSs_sSSs    S.        sSSs_sSSs           .S    S.    .S    sSSs  sdSS_SSSSSSbs    sSSs_sSSs     .S_sSSs     .S   .S_SSSs      sSSs                                                            //
//     d%%SP   d%%SP~YS%%b   SS.      d%%SP~YS%%b         .SS    SS.  .SS   d%%SP  YSSS~S%SSSSSP   d%%SP~YS%%b   .SS~YS%%b   .SS  .SS~SSSSS    d%%SP                                                            //
//    d%S'    d%S'     `S%b  S%S     d%S'     `S%b        S%S    S%S  S%S  d%S'         S%S       d%S'     `S%b  S%S   `S%b  S%S  S%S   SSSS  d%S'                                                              //
//    S%|     S%S       S%S  S%S     S%S       S%S        S%S    S%S  S%S  S%|          S%S       S%S       S%S  S%S    S%S  S%S  S%S    S%S  S%|                                                               //
//    S&S     S&S       S&S  S&S     S&S       S&S        S%S SSSS%S  S&S  S&S          S&S       S&S       S&S  S%S    d*S  S&S  S%S SSSS%S  S&S                                                               //
//    Y&Ss    S&S       S&S  S&S     S&S       S&S        S&S  SSS&S  S&S  Y&Ss         S&S       S&S       S&S  S&S   .S*S  S&S  S&S  SSS%S  Y&Ss                                                              //
//    `S&&S   S&S       S&S  S&S     S&S       S&S        S&S    S&S  S&S  `S&&S        S&S       S&S       S&S  S&S_sdSSS   S&S  S&S    S&S  `S&&S                                                             //
//      `S*S  S&S       S&S  S&S     S&S       S&S        S&S    S&S  S&S    `S*S       S&S       S&S       S&S  S&S~YSY%b   S&S  S&S    S&S    `S*S                                                            //
//       l*S  S*b       d*S  S*b     S*b       d*S        S*S    S*S  S*S     l*S       S*S       S*b       d*S  S*S   `S%b  S*S  S*S    S&S     l*S                                                            //
//      .S*P  S*S.     .S*S  S*S.    S*S.     .S*S        S*S    S*S  S*S    .S*P       S*S       S*S.     .S*S  S*S    S%S  S*S  S*S    S*S    .S*P                                                            //
//    sSS*S    SSSbs_sdSSS    SSSbs   SSSbs_sdSSS         S*S    S*S  S*S  sSS*S        S*S        SSSbs_sdSSS   S*S    S&S  S*S  S*S    S*S  sSS*S                                                             //
//    YSS'      YSSP~YSSY      YSSP    YSSP~YSSY          SSS    S*S  S*S  YSS'         S*S         YSSP~YSSY    S*S    SSS  S*S  SSS    S*S  YSS'                                                              //
//                                                               SP   SP                SP                       SP          SP          SP                                                                     //
//                                                               Y    Y                 Y                        Y           Y           Y                                                                      //
//                                                                                                                                                                                                              //
//     .S_SsS_S.    .S       S.     sSSs   .S_sSSs    sdSS_SSSSSSbs   .S_SSSs      sSSs          sSSs_sSSs     .S       S.     sSSs   .S_sSSs     .S_SSSs     .S_sSSs                                           //
//    .SS~S*S~SS.  .SS       SS.   d%%SP  .SS~YS%%b   YSSS~S%SSSSSP  .SS~SSSSS    d%%SP         d%%SP~YS%%b   .SS       SS.   d%%SP  .SS~YS%%b   .SS~SSSSS   .SS~YS%%b                                          //
//    S%S `Y' S%S  S%S       S%S  d%S'    S%S   `S%b       S%S       S%S   SSSS  d%S'          d%S'     `S%b  S%S       S%S  d%S'    S%S   `S%b  S%S   SSSS  S%S   `S%b                                         //
//    S%S     S%S  S%S       S%S  S%S     S%S    S%S       S%S       S%S    S%S  S%|           S%S       S%S  S%S       S%S  S%S     S%S    S%S  S%S    S%S  S%S    S%S                                         //
//    S%S     S%S  S&S       S&S  S&S     S%S    d*S       S&S       S%S SSSS%S  S&S           S&S       S&S  S&S       S&S  S&S     S%S    S&S  S%S SSSS%S  S%S    S&S                                         //
//    S&S     S&S  S&S       S&S  S&S_Ss  S&S   .S*S       S&S       S&S  SSS%S  Y&Ss          S&S       S&S  S&S       S&S  S&S_Ss  S&S    S&S  S&S  SSS%S  S&S    S&S                                         //
//    S&S     S&S  S&S       S&S  S&S~SP  S&S_sdSSS        S&S       S&S    S&S  `S&&S         S&S       S&S  S&S       S&S  S&S~SP  S&S    S&S  S&S    S&S  S&S    S&S                                         //
//    S&S     S&S  S&S       S&S  S&S     S&S~YSY%b        S&S       S&S    S&S    `S*S        S&S       S&S  S&S       S&S  S&S     S&S    S&S  S&S    S&S  S&S    S&S                                         //
//    S*S     S*S  S*b       d*S  S*b     S*S   `S%b       S*S       S*S    S&S     l*S        S*b       d*S  S*b       d*S  S*b     S*S    d*S  S*S    S&S  S*S    S*S                                         //
//    S*S     S*S  S*S.     .S*S  S*S.    S*S    S%S       S*S       S*S    S*S    .S*P        S*S.     .S*S  S*S.     .S*S  S*S.    S*S   .S*S  S*S    S*S  S*S    S*S                                         //
//    S*S     S*S   SSSbs_sdSSS    SSSbs  S*S    S&S       S*S       S*S    S*S  sSS*S          SSSbs_sdSSSS   SSSbs_sdSSS    SSSbs  S*S_sdSSS   S*S    S*S  S*S    S*S                                         //
//    SSS     S*S    YSSP~YSSY      YSSP  S*S    SSS       S*S       SSS    S*S  YSS'            YSSP~YSSSSS    YSSP~YSSY      YSSP  SSS~YSSY    SSS    S*S  S*S    SSS                                         //
//            SP                          SP               SP               SP                                                                          SP   SP                                                 //
//            Y                           Y                Y                Y                                                                           Y    Y                                                  //
//                                                                                                                                                                                                              //
//                                                                                                                                                                                                              //
//                                                                                                                                                                                                              //
//                                                                                                                                                                                                              //
//     ___                   _                                                                                                                                                                                  //
//    |  _> _ _  ___  ___  _| | ___   ___  ___  _ _                                                                                                                                                             //
//    | <__| '_>/ ._><_> |/ . |/ . \ | . \/ . \| '_>                                                                                                                                                            //
//    `___/|_|  \___.<___|\___|\___/ |  _/\___/|_|                                                                                                                                                              //
//                                   |_|                                                                                                                                                                        //
//     ___       _            _  ___                  _          __ ___       _     __                                                                                                                          //
//    / __> ___ <_> _ _  ___ | ||  _> _ _  _ _  ___ _| |_ ___   / /|  _> _ _ <_> ___\ \                                                                                                                         //
//    \__ \| . \| || '_><_> || || <__| '_>| | || . \ | | / . \ | | | <__| '_>| |<_-< | |                                                                                                                        //
//    <___/|  _/|_||_|  <___||_|`___/|_|  `_. ||  _/ |_| \___/ | | `___/|_|  |_|/__/ | |                                                                                                                        //
//         |_|                            <___'|_|              \_\                 /_/                                                                                                                         //
//                                                                                                                                                                                                              //
//                                                                                                                                                                                                              //
//                                                                                                                                                                                                              //
//                                                                                                                                                                                                              //
//                                                                                                                                                                                                              //
//                                                                                                                                                                                                              //
//                                                                                                                                                                                                              //
//                                                                                                                                                                                                              //
//     __ __  ____  __ __   ____      ___ ___    ___  __ __  ____   __   ___          __   ____  ____   ____   ___   ____     ___  _____                                                                        //
//    |  |  ||    ||  |  | /    |    |   |   |  /  _]|  |  ||    | /  ] /   \        /  ] /    ||    \ |    \ /   \ |    \   /  _]/ ___/                                                                        //
//    |  |  | |  | |  |  ||  o  |    | _   _ | /  [_ |  |  | |  | /  / |     |      /  / |  o  ||  o  )|  D  )     ||  _  | /  [_(   \_                                                                         //
//    |  |  | |  | |  |  ||     |    |  \_/  ||    _]|_   _| |  |/  /  |  O  |     /  /  |     ||     ||    /|  O  ||  |  ||    _]\__  |                                                                        //
//    |  :  | |  | |  :  ||  _  |    |   |   ||   [_ |     | |  /   \_ |     |    /   \_ |  _  ||  O  ||    \|     ||  |  ||   [_ /  \ |                                                                        //
//     \   /  |  |  \   / |  |  |    |   |   ||     ||  |  | |  \     ||     |    \     ||  |  ||     ||  .  \     ||  |  ||     |\    |                                                                        //
//      \_/  |____|  \_/  |__|__|    |___|___||_____||__|__||____\____| \___/      \____||__|__||_____||__|\_|\___/ |__|__||_____| \___|                                                                        //
//                                                                                                                                                                                                              //
//                                                                                                                                                                                                              //
//                                                                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SHMQ is ERC721Creator {
    constructor() ERC721Creator("Solo historias muertas quedan", "SHMQ") {}
}