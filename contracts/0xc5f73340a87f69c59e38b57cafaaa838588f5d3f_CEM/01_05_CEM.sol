// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cem Salur
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMWNXXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkdodxOKXXK0kk0NMMM    //
//    MMMMMMMMW0o;'..';xKXWMMMMMWMMMMMMMMMMMMMMMNK000KNMMMMMMMMNKKNM0loOOo:;;:cokXMMMWx.      ....    ;0MM    //
//    MMMMMNx:;.        ..cKMNx:;:lx0NMMMMMMMMMMk'....xMMMMMMMWd..xWo   .       .oNNX0;               .kMM    //
//    MMMMMk.   'oxxxd'   .lKk.     .'ckNMMMMMMMx.   .dMMMMMMMWo  dWO'  'ddlll'  ,:''dx;',::,.    .';lOWMM    //
//    MMMWKl.  ;OWMMMM0;   .xk.   .;;.  'dXMMMMMx.   .dMMMMMMMWo  oWWKo..lXMMMKl.    oWWWWMMWd.  cKNWMMMMM    //
//    MMMK;   .xMMMMMMWX0OOKWNl  .dWWNOc. 'xNMMMx.   .dWMMMMMMWo  oWNko; ,O000kl.   ;KMMMMMMMk.  oWMMMMMMM    //
//    MMMNx.  .kMMMMMMMMMMMMMMK:  ;KMMMWO;  cXMMx.   .dMMMMMMMWo  oWk.  ....  .,;;;dXMMMMMMMX:   'OWMMMMMM    //
//    MMMMk.  .lXMMMMMWXXX0XWMMXl. ;0MMMMK:  :KMx.   .dMMMMMMMWo  oWx. .dkc.. .',''cKMMMMMMNo     '0MMMMMM    //
//    MMMWx.   .dNMWWWO,...'kWMMWk, 'kNMMMK;  cNO;..  cO0KWMNKO:  oWx.  .oXXK0d,    cNMMMMMO.      cNMMMMM    //
//    MMMMNOo,  .:l:;;'    .kWMMMMXd'.;xKWNl  .kWNXc     ,OWk'   .dWk.   ,KMMMMO.   ;KMMMMMx.      :XMMMMM    //
//    MMMMMMMx.          .l0WMMMMMMWXd;..,,.  .xMMWl      ';.  'dkXMk.   ;XMMMMK;  ,0WMMMMMXc.    'OWMMMMM    //
//    MMMMMMMNkc;;cxoccokXWMMMMMMMMMMMWKxl:;,:xNMMWO:::;;;;::;:kWMMMXdlllkNMMMMWkll0WMMMMMMMNOollxXMMMMMMM    //
//    MMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMWWWMMMMMMMMMMWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMWNXK00KXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMWXkl;'......,ckXMMMMXxlok00kdlc:;:oONMMMXdc::clcccdKX00XWMMMWOlcllllloollclkNMMMMMMMMMMMMMMMMMMMM    //
//    MMXo.             ,xNMXc              .cKMMk.         .. ..oXMMWx.        .'...oNXdclodxkO0KXNWMMMMM    //
//    M0;     .,'. 'xk;  .dWK,      .''.     .dWMK;   .'..,:,    .dNMMW0:  ;lccoONX00KW0'       ...';cd0WM    //
//    X:     ;0NN0:,ox,   ,KNl     cKNNKl.   .OMM0,   ,OXNWWNOl.   ;0WOc'  lNMMMMMWWMMM0'    .'...     .cK    //
//    k.     oWMMM0'      .kM0'    'ldo:.  'l0WMMO'   .xWWMMMMK,   .xWo.  .,::oKOl;:OWM0'    lXNXKOl.    c    //
//    x.     lWMMNl       .kM0'          .cx0WMMM0,   ,KMMMMMMNo.  '0MNOo' .. .;';l:xWM0'    c0XXNNk.   .o    //
//    k.    .xMMMO.       ;KWo       .      .kMMM0,   ,0MMMMMMk.    oWMKl..d0doodKMWWMM0'     ...'..  .;xN    //
//    K;    .OMMM0,      .xW0'     .x0x,     oWMMKc   ,KMMWMWXo.   .kWMNx..dWMMMMMMMMMMO.   .;c;,.   .oXMM    //
//    WO,    ;xOOd.     .xWM0'     .xWMK;    .xNNc     ,c:;:;..   :0WMMMX: .lONK0XKxldXO.   ,KMWWK:   .xMM    //
//    MMKo,           'oKWMMWk'    'kMMMO'    .ONl.          .  .;OMMWOc'    .:;.'.  .xKl,'.lXMMMWo   .dMM    //
//    MMMMNOdc;,',;cdONMMMMMMMXkddkKWMMMW0oc:lxNMNOddxkdlc;:d0OO0NMMMWOc:ccccoO0o::::oKMWWNXNMMMMW0dlcoKMM    //
//    MMMMMMMMWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CEM is ERC1155Creator {
    constructor() ERC1155Creator("Cem Salur", "CEM") {}
}