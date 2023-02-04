// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WhereIDraw
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                   //
//                                                                                                                   //
//                                                                                                                   //
//     .S     S.    .S    S.     sSSs   .S_sSSs      sSSs   .S   .S_sSSs     .S_sSSs     .S_SSSs     .S     S.       //
//    .SS     SS.  .SS    SS.   d%%SP  .SS~YS%%b    d%%SP  .SS  .SS~YS%%b   .SS~YS%%b   .SS~SSSSS   .SS     SS.      //
//    S%S     S%S  S%S    S%S  d%S'    S%S   `S%b  d%S'    S%S  S%S   `S%b  S%S   `S%b  S%S   SSSS  S%S     S%S      //
//    S%S     S%S  S%S    S%S  S%S     S%S    S%S  S%S     S%S  S%S    S%S  S%S    S%S  S%S    S%S  S%S     S%S      //
//    S%S     S%S  S%S SSSS%S  S&S     S%S    d*S  S&S     S&S  S%S    S&S  S%S    d*S  S%S SSSS%S  S%S     S%S      //
//    S&S     S&S  S&S  SSS&S  S&S_Ss  S&S   .S*S  S&S_Ss  S&S  S&S    S&S  S&S   .S*S  S&S  SSS%S  S&S     S&S      //
//    S&S     S&S  S&S    S&S  S&S~SP  S&S_sdSSS   S&S~SP  S&S  S&S    S&S  S&S_sdSSS   S&S    S&S  S&S     S&S      //
//    S&S     S&S  S&S    S&S  S&S     S&S~YSY%b   S&S     S&S  S&S    S&S  S&S~YSY%b   S&S    S&S  S&S     S&S      //
//    S*S     S*S  S*S    S*S  S*b     S*S   `S%b  S*b     S*S  S*S    d*S  S*S   `S%b  S*S    S&S  S*S     S*S      //
//    S*S  .  S*S  S*S    S*S  S*S.    S*S    S%S  S*S.    S*S  S*S   .S*S  S*S    S%S  S*S    S*S  S*S  .  S*S      //
//    S*S_sSs_S*S  S*S    S*S   SSSbs  S*S    S&S   SSSbs  S*S  S*S_sdSSS   S*S    S&S  S*S    S*S  S*S_sSs_S*S      //
//    SSS~SSS~S*S  SSS    S*S    YSSP  S*S    SSS    YSSP  S*S  SSS~YSSY    S*S    SSS  SSS    S*S  SSS~SSS~S*S      //
//                        SP           SP                  SP               SP                 SP                    //
//                        Y            Y                   Y                Y                  Y                     //
//                                                                                                                   //
//                                                                                                                   //
//                                                                                                                   //
//                                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract WID23 is ERC1155Creator {
    constructor() ERC1155Creator("WhereIDraw", "WID23") {}
}