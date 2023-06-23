// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PROMO_CONUSI1155
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                       //
//                                                                                                                       //
//                                                                                                                       //
//                                                                                                                       //
//                                                                                                                       //
//                                                                                                                       //
//      .JJJJJJJ   JJJJJJJ. `JJJ, .JJ   .J,  .J,  .JJJJJJ,   JJ.    (J,   JJ, .JJJJJJJ.  JJJJJJJ,  (JJJJJJ,  .JJJJJJ,    //
//      ,MMMMMMM   MMMMMMM_  MMMN .M#   dM]  dMF  ([email protected]   MM:    JMN  .MM! .MMMMMMM_  MMMMMMM)  dMMMMMM]  JMMMMMMF    //
//      ,MN  .MM   MM`  MM_  MMMM|.M#   dM]  dMF  (MF        MM:    .MM; JM#  .MM        MM}  MM)  dM]       JMF         //
//      ,MN  .MM   MM`  MM_  MMdMb.M#   dM]  dMF  (Mb.....   MM:     MMb MM]  .MM-....   MM{..MM)  dM].....  JMF....     //
//      ,MN        MM`  MM_  MMcMN,M#   dM]  dMF  ([email protected]   MM:     (MN.MM`  .MMMMMMF   MMMMMMM)  dMMMMMM]  JMMMMMM     //
//      ,MN        MM`  MM_  MM}MMdM#   dM]  dMF  (""""[email protected]   MM:     .MMJM#   .MM""""3   MMY"MMY'  7""""MM]  [email protected]""""     //
//      ,MN.....   MM-..MM_  MM}(MMM#   dMb..dMF   ....([email protected]   MM:      MMMM]   .MM-....   MM} MMb    ....dM]  JMF.....    //
//      ,MMMMMMM   MMMMMMM_  MM}.MMM#   dMMMMMMF   [email protected]   MM:      -MMM`   .MMMMMMM_  MM} JMN   .MMMMMM]  JMMMMMMF    //
//      ,"""""""   """""""`  ""' """"   ?""""""5   """""""   ""!      ."""    ."""""""`  ""' .""!  .""""""^  ?""""""5    //
//                                                                                                                       //
//                                                                                                                       //
//                                                                                                                       //
//                                                                                                                       //
//      .&&&&&&&&&&&&&&&&,   .&&&&&&&&&&&&&&&&    (&&&&&&&&&&&&&&&x    &&&&&&&&        .&&&&&&&,    +&&&&&&&&&&&&&&&x    //
//      ,MMMMMMMMMMMMMMMM)   (MMMMMMMMMMMMMMMM    dMMMMMMMMMMMMMMM#    MMMMMMMM|       MMMMMMMM]    MMMMMMMMMMMMMMMMF    //
//      ,MMMMMMMMMMMMMMMM)   (MMMMMMMMMMMMMMMM    dMMMMMMMMMMMMMMM#    MMMMMMMMb      .MMMMMMMM]    MMMMMMMMMMMMMMMMF    //
//      ,MMMMMMMMMMMMMMMM)   (MMMMMMMMMMMMMMMM    dMMMMMMMMMMMMMMM#    MMMMMMMMM.     JMMMMMMMM]    MMMMMMMMMMMMMMMMF    //
//      ,MMMM#      dMMMM)   (MMMMF      MMMMN    dMMMM)     .MMMM#    MMMMMMMMM]    .MMMMMMMMM]    MMMMM_     -MMMMF    //
//      ,MMMM#      dMMMM)   (MMMMF      MMMMM    dMMMM)     .MMMM#    MMMMMMMMMN    .MMMMMMMMM]    MMMMM_     -MMMMF    //
//      ,MMMM#      dMMMM)   (MMMMF      MMMMM    dMMMM)     .MMMM#    MMMMMdMMMM,   dMMMMdMMMM]    MMMMM_     -MMMMF    //
//      ,MMMMNNNNNNNMMMMM)   (MMMMNNNNNNNMMMMM    dMMMM)     .MMMM#    MMMMM,MMMMb  .MMMMFdMMMM]    MMMMM_     -MMMMF    //
//      ,MMMMMMMMMMMMMMMM)   (MMMMMMMMMMMMMMMN    dMMMM)     .MMMM#    MMMMM MMMMN  (MMMM\dMMMM]    MMMMM_     -MMMMF    //
//      ,MMMMMMMMMMMMMMMM)   (MMMMMMMMMMMMMMMM    dMMMM)     .MMMM#    MMMMM JMMMM[ MMMM# dMMMM]    MMMMM_     -MMMMF    //
//      ,MMMMMHHHHHHHHHHH>   (MMMMMHHHMMMMMMHH    dMMMM)     .MMMM#    MMMMM .MMMMb.MMMMF dMMMM]    MMMMM_     -MMMMF    //
//      ,MMMM#               (MMMMF   JMMMMN      dMMMM)     .MMMM#    MMMMM  dMMMMdMMMM` dMMMM]    MMMMM_     -MMMMF    //
//      ,MMMM#               (MMMMF   .MMMMM[     dMMMM)     .MMMM#    MMMMM  ,MMMMMMMMF  dMMMM]    MMMMM_     -MMMMF    //
//      ,MMMM#               (MMMMF    MMMMMN     dMMMMNggggggMMMM#    MMMMM   MMMMMMMM\  dMMMM]    MMMMMggggggdMMMMF    //
//      ,MMMM#               (MMMMF    (MMMMM,    dMMMMMMMMMMMMMMM#    MMMMM   JMMMMMM#   dMMMM]    MMMMMMMMMMMMMMMMF    //
//      ,MMMM#               (MMMMF    .MMMMMb    dMMMMMMMMMMMMMMM#    MMMMM   .MMMMMMF   dMMMM]    MMMMMMMMMMMMMMMMF    //
//      ,[email protected]               (MMMMF     TMMMMB    [email protected]    MMMMM    TMMMMM!   dMMMM%    MMMMMMMMMMMMMMMMF    //
//                                                                                                                       //
//                                                                                                                       //
//                                                                                                                       //
//                                                                                                                       //
//      .(((((((((((((-  .(((((((((((((-  .(((((((((((((.  .(((((((((,  .(((((((((,  .(((((((((((((,  .(((((((((((((,    //
//      ,MMMMMMMMMMMMMM  .MMMMMMMMMMMMMM  ,MMMMMMMMMMMMMN  .MMMMMMMMMF  (MMMMMMMMM]  gMMMMMMMMMMMMMF  dMMMMMMMMMMMMMF    //
//      ,MMMMMMMMMMMMMM  .MMMMMMMMMMMMMM  ,MMMMMMMMMMMMMN  .MMMMMMMMMF  (MMMMMMMMM]  gMMMMMMMMMMMMMF  dMMMMMMMMMMMMMF    //
//      ,MMMMM]          .MMMMM]  dMMMMM  ,MMMMM]  MMMMMN      .MMMMMF      .MMMMM]  gMMMMM`          dMMMMM             //
//      ,MMMMM]          .MMMMM]  dMMMMM  ,MMMMM]  dMMMMB      .MMMMMF      .MMMMM]  gMMMMM`          dMMMMM             //
//      ,MMMMMmJJJJJJ,   .MMMMMmJdMMMM#^  ,MMMMM]              .MMMMMF      .MMMMM]  gMMMMM&JJJ.      dMMMMMJJJJ         //
//      ,MMMMMMMMMMMMF   .MMMMMMMMMMM=    ,MMMMM]              .MMMMMF      .MMMMM]  gMMMMMMMMMMa     dMMMMMMMMMMx       //
//      ,MMMMMMMMMMMMF   .MMMMMMMMMMMN,   ,MMMMM]              .MMMMMF      .MMMMM]  JMMMMMMMMMMMMJ   dMMMMMMMMMMMN,     //
//      ,MMMMM]          .MMMMM]  MMMMMN  ,MMMMM]  ......      .MMMMMF      .MMMMM]  ....... TMMMMMF  ......  TMMMMMF    //
//      ,MMMMM]          .MMMMM]  dMMMMM  ,MMMMM]  MMMMMN      .MMMMMF      .MMMMM]  gMMMMM`  MMMMMF  dMMMMM   MMMMMF    //
//      ,MMMMMmJJJJJJJJ  .MMMMM]  dMMMMM  ,MMMMMmJJMMMMMN      .MMMMMF      .MMMMM]  gMMMMM&JJMMMMMF  dMMMMMJJJMMMMMF    //
//      ,MMMMMMMMMMMMMM  .MMMMM]  dMMMMM  ,MMMMMMMMMMMMMN      .MMMMMF      .MMMMM]  gMMMMMMMMMMMMMF  dMMMMMMMMMMMMMF    //
//      ,MMMMMMMMMMMMMM  .MMMMM]  dMMMMM  ,MMMMMMMMMMMMMM      .MMMMMF      .MMMMM]  JMMMMMMMMMMMMMF  dMMMMMMMMMMMMMF    //
//                                                                                                                       //
//                                                                                                                       //
//                                                                                                                       //
//                                                                                                                       //
//                                                                                                                       //
//                                                                                                                       //
//                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PCV02 is ERC1155Creator {
    constructor() ERC1155Creator("PROMO_CONUSI1155", "PCV02") {}
}