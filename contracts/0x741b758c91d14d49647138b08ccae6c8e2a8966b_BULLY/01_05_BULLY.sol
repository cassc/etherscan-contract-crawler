// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bully Meow Music 55
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                              //
//                                                                                                                              //
//    ...................................':llc;...................................,coo:.....................................    //
//    ...................................ckOkxdl:,.............................':okOocdc'...................................    //
//    ..................................'c:lkKKkxo:,'........................':xKXXKc :x;...................................    //
//    ...................................;'.xWMMWXklcc::;,..,.. ...,,.',,;;;lxKWMMWO' ;o,...................................    //
//    ...................................',dWMMMMMW0c;xOxkl'o;  ..:xc,xkxK0x0NWWWNWNl'lc....................................    //
//    ....................................'dXNWMWXXNklkXXXl.dx.  .lo.cXWNXolKNXNN0kl':l,....................................    //
//    .....................................,o000K0XWMMWNNNo'xO' :kO:.lKNXX00NKkOd;'.,o:.....................................    //
//    ......................................cOo:0MMMMMMWWW0ool..lOdlkNWNNXKXNNN0;.;lo:......................................    //
//    ......................................;O0ONMMMMMWWMWWWx,.':;oXNNWX0XMMWNWWOd00l'......................................    //
//    .......................................oXWMMMMMMNWMWWMk....'xMWWWXKNMMMMMMNXKl'.......................................    //
//    ...................................',:oKMMNXNKdlcoxXMMN0Oxl:kWW0oc::l0MWNWWWXo;'......................................    //
//    ................................,:ldk0WX0O:;Ox;'  .;kWMMMWX0XNxc,  ,;dXl;dxxXKxdoc;'..................................    //
//    ............................';cdkOOOOXM0:..xWXko,.c,;0MMMMMMMO':o,,oxKWO' ..:dlx0OOxo:,...............................    //
//    ..........................,cdkOOOOOOOKOcldkXNXKOkOOddKMMMMMMWxcxO0OOXXKOc..,  .o0OOOOOxo:'............................    //
//    .......................';okOOOOOOOOO0x'lXxlkOOO0XNWMWN0xxddx0XXWWKxkOOxd:.c0c .lOOOOOOOOOxc,..........................    //
//    .....................':dkOOOOOOOOOOOOk:dXoco:;,oNMMMMXl.  'cOMMWWXO:'',:;.;kl .lOOOOOOOOOOOkl,........................    //
//    ....................;dOOOOOOOOOOOOOOO0kc;,.....dWMMMMMWd.;KWMMMMWWNo..''.,,.. ,xOOOOOOOOOOOOOkl,......................    //
//    ..................,okOOOOOOOOOOOOOOOOO0Oc,,,okxKWMMMMMXc .dKNMMMWKkkO00KXNd..;xOOOOOOOOOOOOOOOOx:'....................    //
//    .................:xOOOOOOOOOOOOOOOOOOOOKXx:coxOxoddxxooloollodddc',xK0OOOoccokOOOOOOOOOOOOOOOOOOOo,...................    //
//    ...............'ckOOOOOOOOOOOOOOOOOOOOOOOKK0O0Ol,..  .lxxkxdoc.    .,okO000K0OOOOOOOOOOOOOOOOOOOOOx;..................    //
//    ..............'lOOOOOOOOOOOOOOOOOOOOOOOOOOO0O0XXx;.             .,:,cKNKdccldkOOOOOOOOOOOOOOOOOOOOOx:.................    //
//    .............'lOOOOOOOOOOOOOOOOOOOO0OkxolodddlckXOl,..      ....,;;oOd;.    ..';:loxkOOO0OOOOOOOOOOOx:................    //
//    .............ckOOOOOOOOOOOOOOOOOkdoddddxOKNWNk:dWWNXKK0OkxxkO000o,;dc.             ..';lllxOOOOOOOOOOd,...............    //
//    ............;xOOOOOOOOOOOOOOOOkolx0XNMMMMN0Oc:0WMMMMMMMMMMMMMMMk'.xN0;              'd0K0c.ckOOOOOOOOOo'..............    //
//    ...........'oOOOOOOOOOOOOOOOOOllXMMMMMMWWX0l.:KMMMMMMMMMMMMWMNk'.,dN0;             :XMMMMk..:OOOOOOOOOk:..............    //
//    ...........;xOOOOOOOOOOOOOOO0dcOMMMMMMMNko;...:XMMMMMMMMMMMMNx'.;oxc.             '0MMMMMK; .dOOOOOOOOOo'.............    //
//    ...........cOOOOOOOOOOOOOOOO0lcXMMMMMMMKc.     ;KMMMMMMMMMMMKolxd:.             .:0WMMMMMK: .lOOOOOOOOOx,.............    //
//    ..........'lOOOOOOOOOOOOOOOOO:cXMMMMMWO;.       ,OWMMMMMMMMMWKd,                ;XMMMMMMMK;  cOOOOOOOOOk;.............    //
//    ..........'oOOOOOOOOOOOOOOOOO:lNWNWMMNO:.        .dNMMMMMNkoc.             ..   cNMMMMMMMx.  :OOOOOOOOOk:.............    //
//    ..........'lOOOOOOOOOOOOOOOOk:xMKxKMMMWO,          cXMW0o,               ....   'xXMMMMWO,   ;OOOOOOOOOk:.............    //
//    ...........cOOOOOOOOOOOOOOO0dc0MNdkMMMMXd,          :k:.             .:;cc,.     ,KMMMWK:    ,kOOOOOOOOx;.............    //
//    ...........:kOOOOOOOOOOOOOOOldWMXcdMMMMMWKl.        ':.:Okl:;:ccclodoONXOc.      ;XMMM0:.    .x0OOOOOOOo'.............    //
//    ...........,dOOOOOOOOOOOOOOxckMWx.oMMWNNNXKk;.      .'.oMMMMMMWX0000KKKKKx,      :XMMK:.      cOOOOOOOkc..............    //
//    ............:kOOOOOOOOOOOOOlcKMNo.:dclllllllc;,,.   ;x,:NMMMMMk;;;;,,;;;:c:;;,.  ;XMXc        .xOOOOOOd,..............    //
//    ............'lOOOOOOOOOOOOO:oWM0' ;o;'........';.   .;'oWMMMMWx,,lkkkkoldl'...   ,KMXd'        cOOOOOk:...............    //
//    .............,dOOOOOOOOOO0d:kMX:  '0No.       ':.   .',xMMMMMKcl:dMWWNKxc,.      '0MMNc        :OOOOkc................    //
//    ..............,dOOOOOOOOOO:cXM0,  .xMNd.            .',xMMMMMNkxxKMN0Okl,..      .kMMX:        :OOOkl'................    //
//    ...............,dOOOOOOO0d,dMWk.   oMMN0l.           ,,xMMMMMMMMMMMMWXx:..       .kMWO,        :OOkc'.................    //
//    ................'lkOOOOOOc:KWk'    :NMMMWXl.        .',xMMMMMMMMMMMMWd'..        '0MWd.        :Ox:...................    //
//    .................':xOOOOk:xW0,     ;XMMMMWKxo:...   .',xMMMMMMMMMMMNk:.          ,KM0'         cd,....................    //
//    ...................,lkOOllXNd.     '0MMMMMMMMNK00OOkc',kMMMMMMMMMMMNo.           :NWo         .l:.....................    //
//    .....................;odckMMNd.    .kMMMMMMMMMMMMMMNl.,kMMMMMMMMMX0d,.           lWWl   .lc   ,o,.....................    //
//    ......................'.cXMWKc     .xMMMMMMMMMMMMMMXl.,OMMMMMMMMXd;'.      ..    oM0'  .xk.   cl......................    //
//    ........................dWNk;       dMMMMMMMMMMMMMMKc.;0MMMMMMMMKc.      ,xd.   .xWd. .xO,   'o;......................    //
//    .......................;KMk.        cNWWWMMMMMMMMMMO:':KMMMMMMM0:''. 'oxOOo.    .O0'  l0;    cl.......................    //
//    .......................xWK;       ..;ko;:oKMMMMMMMMk;.cXMMMMMMMKdxK0kKWW0;      :Kl  :k:    'o;.......................    //
//    ......................cXXc        :c'od.  'clkNNWMMx,.oWMMMMMMMMMMMMWXKk;.      dK; .oc.    cl........................    //
//    ......................kMNo.      :o,.'kx.    ..,:cko,,oWMMMMMMMMMMW0l,,'.      .OK::d;     ,o,........................    //
//    .....................:XNNk,     :o,...'okc.       ..',oWMMMMMMWWNkc.           cNNXXd.    .o:.........................    //
//    ....................'kM0c.    .co,......,odl;'.     .,lOXXNNNWKd:..          ..xMWNo.    .lc..........................    //
//    ....................lNWO'    .cl'........ .::;,'.,:'.:dooolc::c;..''..  .. .c;cKMWd.    .lc...........................    //
//    ....................ckO:    .lc'..........'::;:::odcxNMMMMKkl:cc;:c:cc,'::.:c.oWWk.    .ll'...........................    //
//    .....................',.   'o:........... .,;,,:cc:oKWMMMMX0o:cc;;:;lo:,::.::;0M0,    .cl'............................    //
//    ......................''..;o;..............,,.'',ll,'cxkkkxo;,;;,'.',;.....;;lNNd.    :o,.............................    //
//    .......................'';:,..............',;;;;,,,,,,,,,,,,,,,,,,,,,,,,,,;:,,ll.    :o,..............................    //
//    ........................................................''''''''',,,'''''....'''''.':l,...............................    //
//    .................................................................................',;:'................................    //
//                                                                                                                              //
//                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BULLY is ERC721Creator {
    constructor() ERC721Creator("Bully Meow Music 55", "BULLY") {}
}