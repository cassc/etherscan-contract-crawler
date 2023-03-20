// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Big Fat Stupid Dingus
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNOdoodONWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKooc,'cooKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNkco:..:ockNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0OXWMMMMMOco:,dOlcocOMMMMMWXO0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0dlcokXMMMWkco;,ONdcockMMMWXkocld0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXcll':cokkkolo:,cONKocolokkkolc,olcXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWXKKKNMMMMXcll,::l:.  ,d;,lOWWx:d,  .:lcd:llcXMMMMNKKKXWMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMKxdooodxO0xc'll.,ooc:''cc;:lOWW0lcc'':cdOx;ll'cx0OxdooodxKMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMxcxl:c::cl;. ll.'okx:lko:;ckXWMKocdkl:kKk:.ll .;lc:lc,cxcxMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWK0Od::l:::'.;;;,,c:.'xO;lxdx,;0MMMkcxdxlcXKl':c,,:clolc,,lc:dOOKWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMNo. .. .;l:cl'...lddl..cxdlooocl0MMMOccllokKx;'ldol:d00l.'c;. .. .dNMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMM0' .oc   ;l;:l:'.';;...'o00KKKOx0MMMXxclxKNOc'.,cld0Kk:.'c;   co. ,0MMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMM0' .'.    ;l;cdo,';;....,d0NWN0xOWMMWKkOXW0l'':x0XXk:..'l;    .'. '0MMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMM0'       .'ll,:oo:,,;:,..cxdolccdKNXklclodl'.'cxXNd,..'ll'.       '0MMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMW0l.     .cO0lll,:dxd:;lxxl;:oxd;..;c;.,:c:,.'co:':c'..'dxldxc.     .l0WMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMWk'      'kXOdlcoc';lcclxO00kk0kl:,.   .:ok0kdk0k:......;ol:ldkd'      'kWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMWk'     .:OXOllccxc..:lxO0Oxooool,..    ..cooooxO0Odl:,',clc'cocOO:.     'kWMMMMMMMMMMMM    //
//    MMMMMMMMMMMWk'     .oNMKooc;c;..,;cdO0k:.    ...   ...'.   .:dO00OOOOxc,'cockNNo.     'kWMMMMMMMMMMM    //
//    MMMMMMMMMMWk'     .lNMMW0:;cdc.':oO0Ox:.         ....        .;dO00OOOkxxccolOMNl.     'kWMMMMMMMMMM    //
//    MMMMMMMMMMX:     .lXMMMNkc;:;';oO000o. 'lxl;cddcll;cdo:;oxl.   .;x0kooxO0oclcdXMXl.     ;XMMMMMMMMMM    //
//    MMMMMMMMMXo.    .lXMMNOdc;';ldO0OO0o..c0WMMWWXO0OddddddxKMW0c.   'xOkl,:xOl:ocxMMXl.    .oXMMMMMMMMM    //
//    MMMMMMMMMK,     .OMNOdc;';oxxool:oO: .lXMMMMWK000OOO0K0XWMMMKc. ..,x0Ol,;l;;dcxMMMO.     ,KMMMMMMMMM    //
//    MMMMMMMMNd.    .cKNdll,,::,.. ..,ol.'dKNWMMMXkddddddO0OKWMMMXl. :o,;k0Ol,. 'ocdWMMKc.    .dNMMMMMMMM    //
//    MMMMMMMNd.     '0Ndll::;. ...,cldl.'xNXkxkkKWMMMMMMMMMMMMWKKKk;.,xxxO00O; ..;olkWMM0'     .dNMMMMMMM    //
//    MMMMMNx,       '0Xcll...;lxxdl,..  ,dkoc'..;lx0NMMMMNKOo:;',cdo. .:xO0Ol,;lolcllkWM0'       ,xNMMMMM    //
//    MMMWk, .::.    '0Nkll,'oOkl'.    .....',,,,,,,ckNMWNk:.   .'''.    .:xk,.:dOklcllkN0'    .::. ,kWMMM    //
//    MMMWx. .ll.    '0MNllo;dk;  ...';:,'.         .'x0d:..         ..    .,. .ck0k;llcX0'    .ll. .xWMMM    //
//    MMMMWKl.       '0MWxll,,c;. .;okkc.:Oo'..     .oKKko.       .'lO:   ..    .oOk;llcX0'       .oKWMMMM    //
//    MMMMMMWKl.     .cKMW0dl;'.  .lO0k, ;KNKk:.....:KMMMNo,,'...'l0WNc  ..,;;.  'od:lloOc.     .lKWMMMMMM    //
//    MMMMMMMMWO'     .OMMMWxcl,...lkOl.  :KNkokKKxlOWMWWkcxKXKKKKXWNx. 'l:cdo'....'lloXk.     'OWMMMMMMMM    //
//    MMMMMMMMMXl.    .lXMMXdcl:;;. ,do.   ,dkXWW0ddXMMMMXK0xdKMMMMNx. .lO0Od:',:'.cloKXl.    .lXMMMMMMMMM    //
//    MMMMMMMMMMX;     .lNWxcd;;do, .clc,.    ';;..oXMMMMMMXo':OXW0:.   :O0x'.':;;cloKXl.     ;XMMMMMMMMMM    //
//    MMMMMMMMMMWk'     .oNxco,.:xl. .ckOx;     .;,':xxxO0xc;::,,;'  ,, .ckd. .:,;dcdXl.     'kWMMMMMMMMMM    //
//    MMMMMMMMMMMWk'     .oKxcl'.cx:  .lko;:c..lk0Ol.   ....o00k;   ,dkl;;;.   ..,d:ol.     'kWMMMMMMMMMMM    //
//    MMMMMMMMMMMMWk'     .:lc:'..;,.  .;;:kd:oOxoc.       ;k0kollooxOOO0d'  .;:;:c'..     'kWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMWk'   .';,',;,.....  ...'...,.           ',;..:xkdxkxxxxc..:;,;;.      'kWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMW0l. .cc:ccccdl';;. ',.                       .;:;oko:cdc. '::c:.   .l0WMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWO'  ......co.,:;.'lo:.   ...';',:c;.  .        :c,'..,. .;;;cc. 'OWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMX;        .;:cdd;;x0x:..,;:lddllxkd:;col;'.    ..  ... .,:::,.  ;XMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMX; .:;      .;o;;oxl,.;oo,.....','..,,,cc,.    .'...,;,.:x:.::. ;XMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMX:  ,;.     .;c;,;'. .'col:'.             ..  ..,::,.;:.co..;,  :XMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMW0l;,,,,,,.   .;:::ld:,lOo'.';,';::;,,.. .cd:. :o;.';ol:ll;,,,;l0WMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWWWWWWW0c'.    .co;cxo' 'oO0Oo;lkOo'.'.'cl;.'odll:,lx0NWWWWWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0dc,'::,,;;. .;cxOk; .ckd,,c:::;;,..,ldd0WMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkocccld; .'..;'. .;l:,oc..,:cccclxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXOkkkxl;...c:.;dl;,;:lclxkkkkkkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0dl:coc;::' 'okKWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0xkOd,..'oKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX00XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BFSD is ERC1155Creator {
    constructor() ERC1155Creator("Big Fat Stupid Dingus", "BFSD") {}
}