// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CryptoKolams
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                   _oo_                                                                   //
//                                                                 _oBBBBk_                                                                 //
//                                                               _kBBBRWBBBk"                                                               //
//                                                             _kBBBW|``|HBBBk"                                                             //
//                                                           "kBBBH|`     |HBBBk"                                                           //
//                                                         "kBBBH|    !!    !HBBBm"                                                         //
//                                                       "mBBBH|    !bBB$*    !HBBBm"                                                       //
//                                                     "mBBBH!    >bBBBBBB$*`   !6BBBm\                                                     //
//                                                     "pBBBd"   `i8BBCKBB8i.   "GBBBH|                                                     //
//                                                       "OBBBd=   `/8BB8i`   "dBBBH!                                                       //
//                                                         "GBBBd=   `//`   "dBBBH"                                                         //
//                                                           "9BBBd=`     =dBBBE!                                                           //
//                                                             ^9BBBW=``=dBBBE!                                                             //
//                                         !"                    "OBBBddBBBH|                    "!`                                        //
//                                      `+mBBE"                    !WBBBBN!                    "GBB8+`                                      //
//                                    `+8BBBBBBp"                 =dBBBBBBd=`                "GBBBBBB8?`                                    //
//                                  `+8BBB6^"OBBBH1             =dBBBE!"GBBBW=`            "OBBBH""aBBB8v`                                  //
//                                `v8BBBa^    "GBBBp1        `=dBBBE!    ^9BBBW=`        "OBBBH"    ^aBBB8v.                                //
//                              .v8BBBa^   ..   "GBBBH1`   `=WBBBE^   ``   ^ABBBWi`    rdBBBE"   ..   ~aBBB&?.                              //
//                            .v&BBBa^   'TN&v.   ^GBBBW1.iWBBBE^   `t&&t'   ^ABBBWi.1OBBBE"   .v&Ny'   ~aBBB&v.                            //
//                          .v&BBBa~   'VNBBBB&{.   ^GBBBBBBBa^   't&BBBBNt'   ^ANBBBBBBE"   .v&BBBBNy~   ~nBBB&{.                          //
//                         .aBBBBY`   'EBBBCKBBBa.   .aBBBBBS`   `6BBBCKBBB6-   `{BBBBBa.   .aBBBBBBBBb-    YBBBBa.                         //
//                           _PBBBW1`   !%BBBBk"   .iQBBBKBBBWL.   "4BBBBm"   `LWBBBmNBBQY.   _kBCKBm!   `1HBBBP"                           //
//                             _PBBBWL`   "%k_   .iQBBBa: ^ANBBgL.   "44"   `LWBBBA^ ,sNBBQY.   _k%!   `1WBBBP_                             //
//                               _eBBBWL`      .YQBBBF:     ,ANBBgL.      .LWBBBA^     ,sQBBQY-      `1WBBBP_                               //
//                                 _eNBBWL.  ,YQBBBF:   _L'   ,sNBBgz.  .LQBBNA:   'L_   .sQBBNY-  `LWBBBe_                                 //
//                                   -eNBBg)YNBBMF:   _yBBNo_   ,sNBBgFsQBBBA:   'oNBB4_   .sQBBNYcWBBBe_                                   //
//                                     -eNBBBBMF.   _wBBBBBBBo_   ,sgBBBBNz:   _oNBCKBBB4"   .LgBBBBNe_                                     //
//                                     ,eNBBBBgz.   _hBBCKBBBo_   ,YQBBBBNz:   _oNBBBBBBw"   .LgBBBBNe_                                     //
//                                   .YQBBBCeBBBWL.   "hBBB4"   .LQBBNAANBBgz.   _4BBBm"   `LWBBBeugBBNY-                                   //
//                                 -YQBBMF:  _eNBBML.   "s_   .LQBBNA:  ,sNBBgz.   _s"   `LWBBBe_  .sgBBNY-                                 //
//                               ,YNBBMF.      -eNBBgL.     .YQBBNz:      ,sQBBgz:     .LWBBNe_      .LQBBNe-                               //
//                             ,eNBBMF.   _S2-   -YNBBgz. ,sQBBNz:   _oo_   .sQBBNz: .LMBBNe-   -oh"   .LgBBNe-                             //
//                           -eNBBML.   "wBBBN2_   -YNBBg4NBBgz:   _oBBBB4_   .sQBBN4gBBNe-   -2NBBB4"   .LWBBNe_                           //
//                         .oNBBBC.   'SBBBCKBBBy.   -aBBBBBh.   `4BBBCKBBB4-   .zBBBBBa-   .yNBBCKBBBm'   `FBBBBo.                         //
//                          '{NBBMC'   ~hBBBBBNo'   ,ANBBBBBNF:   _yNBBBBBy_   :zgBBBBBNA^   'tNBBBBBh"   .cMBBNo'                          //
//                            '{NBBMC~   ~yBNt'   ,ANBBgL~YQBBNA:   'yNNy_   :zNBBQY~LWBBBA^   'tNBh~   'CMBBN{'                            //
//                              '{&BBBC~   ~'   ^ANBBWL.   .iQBBNA:   ''   :zBBBQY.   `LWBBBA^   '~   .CMBBN{'                              //
//                                .{&BBBC~    ^ABBBWL`       .i8BBBA^    :ANBBQi.       `1WBBBE^    ~CMBB&{'                                //
//                                  .v&BBBa~^GBBBWL`           `iWBBBA^^ABBBQi.           `1WBBBE^~CBBB&{.                                  //
//                                    .v&BBBBBBW1`               `iWBBBBBB8i.               `1OBBBBBB&{.                                    //
//                                      .v8BBH1`                   "WBBBBN"                    1OBB&v.                                      //
//                                        `*1                    ^EBBB8WBBBE"                    1*.                                        //
//                                                             ^EBBBW=``=dBBBE"                                                             //
//                                                           "EBBBd=`     =dBBBE"                                                           //
//                                                         ^ABBB8i`   ""   `=WBBBE^                                                         //
//                                                       ^EBBBWi`   "qBBd/   `=WBBBE^                                                       //
//                                                     ^EBBB8=`   /qBBBBBBq/`  `=dBBBE!                                                     //
//                                                     +8BBB%^   `TRBBCKBBRT'   ^SBBB8v                                                     //
//                                                      `+8BBB6!   `>RBBRx`   ^6BBB8+`                                                      //
//                                                        `+mBBB6!   `>>`   ^6BBB8+`                                                        //
//                                                           +mBBB6!      !6BBBm+`                                                          //
//                                                             "mBBBb!  !6BBBm+                                                             //
//                                                               "mBBBbHBBBm+                                                               //
//                                                                 "4BBBBm"                                                                 //
//                                                                   "4k"                                                                   //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CK is ERC721Creator {
    constructor() ERC721Creator("CryptoKolams", "CK") {}
}