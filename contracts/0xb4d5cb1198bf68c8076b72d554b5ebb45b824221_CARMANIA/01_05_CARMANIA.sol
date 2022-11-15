// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CarMania
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMM?777777?NMMMMC7777777HMMMMO7777777QMMMMMMQ77$MMMMMMMMMMN7777777CN?7?MMMMMMMMMCNMMMMMC7777777QMM    //
//    MMMN>        HMMM?        $MMMC.       ?MM$>>>-  ;>>>CMMMMMH!       ;Q   >>>7MMMM7.QMMMM?.       OMM    //
//    MMN>.;COOC;.;HMM?..?OOO-..$MMC;.7OOO!..CM$-    ...   ;CMMMH! -OOO?..-Q;..   .>MM7..HMMM?;.?OOO:..OMM    //
//    MMH  ;MMMN.  HMM;  HMMM-  $MM:  OMMM>  ?$; :CC!  -CC> .CMM$  -MMMH  ;Q. .?C?  >H.  HMMM-  QMMM:  OMM    //
//    MMH;.-NMMN;.CMMM-..QMMM:..$MM!..OMMM7..C? .?MMC..7MM$..!MM$..:MMMH..-Q;.-MMM;..H-..?MMM:..QMMM!..OMM    //
//    MMH  ;NMMN;?MMMM;  QMMM-  $MM!  OMMM>  C7  7MM?  >MMO  :MM$  -MMMQ  ;Q. .NMN. .Q;  !MMM-  $MMM:  OMM    //
//    MMH;.-NMMMQMMMMM-..QMMM:..$MM!..OMMM7..C?..?MMC..7MMO..!MM$..:MMMH..-Q;.;NMN;.;H-..>MMM:..QMMM!..OMM    //
//    MMH. ;NMMMMMMMMM;  QMMM-  $M?.  -!!!; !H7  7MM?  >MMO  :MM$  -MMMQ  ;Q. .NMN. .Q;  !MMM-  $MMM:  OMM    //
//    MMH;.-NMMMMMMM>!...:!!!;..$?;....   .7NM?..?MMC..7MMO..>Q!:..;!!!:..-Q;.;NMN;.;H-..>M7!;..:!!!;..OMM    //
//    MMH. ;NMMMMMMM$.          $Q$-      >NMM7  7MM?  >MMO  !N7          ;Q. .NMN. .Q;  !M$;          OMM    //
//    MMH..;NMMN>NMMMQ;..OQQQ-..$?:;..... -::$?. ?MMC. 7MMO. !MMC..-QQQO..-Q;.;NMN;.;H-..$MMH-..CQQQ:..OMM    //
//    MMH. ;NMMN.:NMMM;  HMMM:  $Q-          C?  7MM?  >MMO  :MM$  -MMMH  -Q. ;NMN. .Q;  HMMM-  QMMM!  OMM    //
//    MMH. ;NMMN; :NMM-..QMMM:. $MN:..?HHH!. C?  ?MMC  7MMO. !MM$. :MMMH. -Q; ;NMN; ;H-..HMMM:..$MMM!  OMM    //
//    MMH. ;NMMN. .HMM;  QMMM:  $MM!  OMMM>  C?  7MM?  >MMO  !MM$  -MMMQ  -Q. ;NMN. .Q; .HMMM-  $MMM!  OMM    //
//    MMH. .----.;QMMM- .QMMM:.OMMM!  OMMM7  CN7 ?MMC  7MMO !NMMM$.:MMMH.-HMQ;;NMN;;QN;.$MMMM:  $MMM!.CMMM    //
//    MMH...    .$MMMM-..QMMM:CMMMM! .OMMM>  ?MN>7MMC..7MMO:HMMMMMO:MMMQ-QMMM$-NMN-$MM-OMMMMM:..QMMM!?MMMM    //
//    MMMHHHHHHHNMMMMMNHHMMMMNMMMMM!.OMMMMN> ?MMNNMMNHHNMMMNMMMMMMMNMMMMNMMMMMNMMMNMMMNMMMMMMNHHMMMMNMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMM>CMMMMMMN!?MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CARMANIA is ERC1155Creator {
    constructor() ERC1155Creator() {}
}