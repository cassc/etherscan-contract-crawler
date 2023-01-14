// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Socks - VV Edition
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                           //
//                                                                                           //
//    RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR    //
//    RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR    //
//    RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR+.             *RRRR    //
//    RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR                  RRR RRR    //
//    RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR*      :  @  R   #   RRR RRR    //
//    RRRRRRRRRRRRRRRRRRRRRRRRRR,     RRRRRRRRRRRRRRRRRRRRRR RRR                  RRR  RR    //
//    RRRRRRRRRR                     R @RRRRRRRRRRRRRRRRRRR  R+           +RRRRRRRRR   RR    //
//    RRRRRRRRR .      R         , +RR  RRRRRRRRRRRRRRRRRRR  RRRR*+*RRRRRRRR**+:.      RR    //
//    RRRRRRRR+RR  ,   R     :R, *RRR   RRRRRRRRRRRRRRRRRRR   ,RRRRR# ,RR       +      RR    //
//    RRRRRRRR +RRRRRRRRRRRRRRRRRRR    [email protected]        R   .:   R    :    #RR    //
//    RRRRRRRR  ,RRRRRRRRR#*:,         RRRRRRRRRRRRRRRRRRRR        R        R    R  # RRR    //
//    RRRRRRRR  R                      RRRRRRRRRRRRRRRRRRRR        R    ,   R*   R  . RRR    //
//    RRRRRRRR  R   #         @        RRRRRRRRRRRRRRRRRRRR        @    @   *R   R    RRR    //
//    RRRRRRRR  R   R    R    R    :   @RRRRRRRRRRRRRRRRRRR.   *   .    :    R   R    RRR    //
//    RRRRRRRR  R   R    R    #    R    RRRRRRRRRRRRRRRRRRRR   R    #        R   ::   RRR    //
//    RRRRRRRR  @   #    R    #    R    RRRRRRRRRRRRRRRRRRRR   .    R        R    #   RRR    //
//    RRRRRRRR   +  ,    R    #:   R    RRRRRRRRRRRRRRRRRRRR        R    .   R    R    RR    //
//    RRRRRRRR:  R   +   R    *R   +:    RRRRRRRRRRRRRRRRRRR        R    R        R    RR    //
//    RRRRRRRR#  R   R   R    :R    R    RRRRRRRRRRRRRRRRRRR    .        *             RR    //
//    [email protected]  R   R   R:    R    R    RRRRRRRRRRRRRRRRRRR    R                     RRR    //
//    RRRRRRRR#  R   +    R    R    @    RRRRRRRRRRRRRRRRRRR                        RRRRR    //
//    RRRRRRRR*  ,    :   R              RRRRRRRRRRRRRRRRRRR#               .#RRRRRRRRRRR    //
//    RRRRRRRR*                         RRRRRRRRRRRRRRRRRRRRRRRR#+*#RRRRRRRRRRRRRRR RRRRR    //
//    RRRRRRRRR                      RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR#:            RRRRR    //
//    RRRRRRRRR      :RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR                    RRRRR    //
//    RRRRRRRRRR  RRRRRRRRRRRRRRRR.   RRRRRRRRRRRRRRRRRRRRRRRRRR                    RRRRR    //
//    RRRRRRRRRRRRRR                  RRRRRRRRRRRRRRRRRRRRRRRRR+                    RRRRR    //
//    RRRRRRRRRRRRR                   #RRRRRRRRRRRRRRRRRRRRRRRR:                    RRRRR    //
//    RRRRRRRRRRRRR                    RRRRRRRRRRRRRRRRRRRRRRRR:                    RRRRR    //
//    RRRRRRRRRRRRR                    RRRRRRRRRRRRRRRRRRRRRRRR+                    *RRRR    //
//    RRRRRRRRRRRRR                    RRRRRRRRRRRRRRRRRRRRRRRR#                     RRRR    //
//    RRRRRRRRRRRRR                    [email protected]                     RRRR    //
//    RRRRRRRRRRRRR                     RRRRRRRRRRRRRRRRRRRRRRR*                     RRRR    //
//    RRRRRRRRRRRRR                     RRRRRRRRRRRRRRRRRRRRRRR.                    RRRRR    //
//    RRRRRRRRRRRRR                     RRRRRRRRRRRRRRRRRRRRRRR                   RR,RRRR    //
//    [email protected]                   #RRRRRRRRRRRRRRRRRRRRRRRR                  R    RRR    //
//    RRRRRRRRRRRR.                 RR# +RRRRRRRRRRRRRRRRRRRRRR                 R      RR    //
//    RRRRRRRRRRRR                @RR    RRRRRRRRRRRRRRRRRRRRRR                ,R      RR    //
//    RRRRRRRRRRRR               RRR     RRRRRRRRRRRRRRRRRRRRR#                R.      RR    //
//    RRRRRRRRRRRR               R*      RRRRRRRRRRRRRRRRRRRRR                 R       #R    //
//    RRRRRRRRRRRR              R#       RRRRRRRRRRRRRRRRRRRRR                 R       @R    //
//    RRRRRRRRRRRR              R       .RRRRRRRRRRRRRRRRRRRRR                ,R       RR    //
//    RRRRRRRRRRR               R       #RRRRRRRRRRRRRRRRRRRR                  R       RR    //
//    RRRRRRRRRRR               R       RRRRRRRRRRRRRRRRRRRRR                  R       RR    //
//    RRRRRRRRRRR               R       RRRRRRRRRRRRRRRRRRRR,                  R.     *RR    //
//    RRRRRRRRRR+               @       RRRRRRRRRRRRRRRRRRRR                    R     RRR    //
//    RRRRRRRRRR                 R     RRRRRRRRRRRRRRRRRRRR                     R    RRRR    //
//    RRRRRRRRRR                 R    *RRRRRRRRRRRRRRRRRRRR                      R  +RRRR    //
//    RRRRRRRRR                   R   RRRRRRRRRRRRRRRRRRRR                       [email protected]    //
//    [email protected]                   R#,RRRRRRRRRRRRRRRRRRRR+                        RRRRRRR    //
//    RRRRRRRR                     RRRRRRRRRRRRRRRRRRRRRR                        RRRRRRRR    //
//    RRRRRRR                     RRRRRRRRRRRRRRRRRRRRRR                        +RRRRRRRR    //
//    RRRRRRR                    RRRRRRRRRRRRRRRRRRRRRR:                        RRRRRRRRR    //
//    RRRRRR                    RRRRRRRRRRRRRRRRRRRRRRR                        RRRRRRRRRR    //
//    RRRRR,                    RRRRRRRRRRRRRRRRRRRRRR                        RRRRRRRRRRR    //
//    RRRRR                    RRRRRRRRRRRRRRRRRRRRRR,                       ,RRRRRRRRRRR    //
//    RRRR                    .RRRRRRRRRRRRRRRRRRRRRR                        RRRRRRRRRRRR    //
//    RRRR                    RRRRRRRRRRRRRRRRRRRRRR                        RRRRRRRRRRRRR    //
//    RRRRRRRRR.              RRRRRRRRRRRRRRRRRRRRR#                       ,RRRRRRRRRRRRR    //
//    RRR     :RRR,          [email protected]*                   RRRRRRRRRRRRRR    //
//    RR          @R,        RRRRRRRRRRRRRRRRRRRRR+      ,RR              RRRRRRRRRRRRRRR    //
//    RR            ,R      RRRRRRRRRRRRRRRRRRRRRR          RR            RRRRRRRRRRRRRRR    //
//    RR              *    :RRRRRRRRRRRRRRRRRRRRR#           ,RR         RRRRRRRRRRRRRRRR    //
//    RR               ,   RRRRRRRRRRRRRRRRRRRRRR.             RR       RRRRRRRRRRRRRRRRR    //
//    RR                R RRRRRRRRRRRRRRRRRRRRRRR.              #R     *RRRRRRRRRRRRRRRRR    //
//    RR+               :RRRRRRRRRRRRRRRRRRRRRRRR#               *R    RRRRRRRRRRRRRRRRRR    //
//    RRR               @RRRRRRRRRRRRRRRRRRRRRRRRR                R:  RRRRRRRRRRRRRRRRRRR    //
//    RRR               RRRRRRRRRRRRRRRRRRRRRRRRRR                 R RRRRRRRRRRRRRRRRRRRR    //
//    RRRR             RRRRRRRRRRRRRRRRRRRRRRRRRRR                 RRRRRRRRRRRRRRRRRRRRRR    //
//    [email protected]          ,RRRRRRRRRRRRRRRRRRRRRRRRRRRR.                RRRRRRRRRRRRRRRRRRRRRR    //
//    RRRRR#        RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR               RRRRRRRRRRRRRRRRRRRRRRR    //
//    RRRRRRR,  :RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR,           @RRRRRRRRRRRRRRRRRRRRRRRR    //
//    [email protected]      #RRRRRRRRRRRRRRRRRRRRRRRRRRR    //
//    RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR    //
//    RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR    //
//                                                                                           //
//                                                                                           //
//                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////


contract SOCKS is ERC1155Creator {
    constructor() ERC1155Creator("Socks - VV Edition", "SOCKS") {}
}