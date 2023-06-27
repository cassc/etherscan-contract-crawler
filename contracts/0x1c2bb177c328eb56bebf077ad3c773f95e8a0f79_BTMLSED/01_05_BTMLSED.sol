// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bottomless Editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//                                                                                                                                 //
//    tMQMk                                                                  <MQMB                                                 //
//    tMMMw                    ^KUDS   ^KUD4                                 <MMMN                                                 //
//    tMWMA                    iMMMB   ^MMMN                                 <MWM&                                                 //
//    tMWM6<NQU      yNQNA;    YMMMNi  eMMMNi    <KQQB(     LILMAHNAJIEM1T   <MWM&     CNQN6+     ^ANQNP+     eBQQKf               //
//    tMMMWMMMMD    BMMMMMMr  ^MMMMMW "MMMMMM   (MMMMMMk   +MMMMWMMMNUMMMM"  <MWM&    QMMMMMM;   ^MMMMMMM+   kMMMMMMC              //
//    tMMMMNMMMW   3MWMNQMMQ  ^MMMMMN +MMMMMQ   MMMQNMMMt  +WMMMNWMMMQQMWMe  <MWM&   CMWM&WMMB   AMWMBMMM6  ^MMMQNMMM"             //
//    tMWMw MMMW~  DMMM~6MWMi  fMWMB   tMMM&   <MWMY^MWMw  +WMMQ KMWM^(MWMY  <MWM&   &MMM UMMM"  BMMB BMMK  tMWMirMWMr             //
//    tMWM6 QMMW~  NMMM 4MWMf  iMWMK   ^MMMB   eMWMe"MMMB  +WMM& UMMM"fMWMY  <MWM&   QMMW 6MWM<  &MMB BMMB  fMWMi^MMM<             //
//    tMWMk QMMW~  QMMM 4MWMv  <MWMK   iMMMB   YMWM3;MMMB  +WMMN UMMM"fMWMY  <MWM&   QMMMiUMWMt  BMMM( +^+  <MWMB+ "^              //
//    tMWMk QMMW~  QMMM 4MWMv  <MWMK   iMMMB   yMWM3;MMMB  +WMMN UMMM"fMWMY  <MWM&   QMMMMMMMMt  SMWMM6     +MMMMQt                //
//    tMWMk QMMW~  QMMM 4MWMv  <MWMK   iMMMB   yMWM3;MMMB  +WMMN UMMM"fMWMY  <MWM&   QMMMMMMMMf   QMMMMMe    eMMMMMB               //
//    tMWMk QMMW~  QMMM 4MWMv  <MWMK   iMMMB   yMWM3;MMMB  +WMMN UMMM"fMWMY  <MWM&   QMMW<;"";     UMMMMMe    tMMMMMQ              //
//    tMWMk QMMW~  QMMM 4MWMv  <MWMK   iMMMB   yMWM3;MMMB  +WMMN UMMM"fMWMY  <MWM&   QMMW rUPwi     <WMMMQ      AMMWM(             //
//    tMWMk QMMW~  QMMM 4MWML  <MWMK   iMMMB   yMWM3;MMMB  +WMMN UMMM"fMWMY  <MWM&   QMMM YMMML  yDUY+QMMM+ ^DwU;eMWMS             //
//    tMWM6 QMMW~  NMMM SMWMt  rMWMK   iMMMB   3MWMe"MMMK  +WMMN UMMM"fMWMY  <MWM&   QMMW eMWMt  BMMQ 4MWM" rMMM< MWMS             //
//    tMWMU WMMW   BMMM+6MWM\  rMWMB   iMMMN   fMWMY^MWMk  +WMMN UMMM"fMWMY  <MWM&   &MMM yMWM\  AMMQ kMMW  ^MWMf+MWMy             //
//    tMMMMQMMMQ   yMWMNWMMQ   \MMMM&  ^MMMMN+ +MMMQQMMM<  +WMMN UMMM"fMWMY  <MWM&   YMWMNWMM&   eMWMNMMM&   QMMQQMMMt             //
//    fMMMQMMMMS    QMMMMMMi    &MMMM+  BMMMM"  yMMMMMMk   +MMMQ KMMM"vMMMC  tMMMQ    BMMMMMM\    &MMMMMM<   vMMMMMMK              //
//    \APwr\BQC      SBNNA^      YP6P    ZP66    fDNNK(     P6kC 3APA iwPwt  ^APky     3BNNA;      ZBNNwi     \ANNBY               //
//                                                                                                                                 //
//                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BTMLSED is ERC1155Creator {
    constructor() ERC1155Creator() {}
}