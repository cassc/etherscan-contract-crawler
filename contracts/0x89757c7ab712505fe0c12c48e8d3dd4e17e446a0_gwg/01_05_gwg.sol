// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Get well Gordon
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOxl:;,'..............';lx0NMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNWMMMMMMMMMMMMMMMMMMMMW0d:...':clodxkOO000000Okdl:'..,lONMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMXOoc;,'',;lkKWMMMMMMMMMWXOkdl,..'cx0NWMMMMMMMMMMMMMMMMMMWN0d;..,xNMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMKl' .,:lool;. .;lxO00Oxoc,.     .;oxk0KNMMMMMMMMMMMMMMMMMMMMMMW0l. ;0MMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMO' 'dKWMMMMMWXko;........',;::::c:::;,,,,:d0WMMMMMMMMMMMMMMMMMMMMW0, .dXMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMK; '0MMMWKxolloxKWNKOkkOKXWWMMWWNNNWMMWX0kl,.:OWMMMMMMMMMMMMMMMMMMMMXo. 'dXMMMMM    //
//    MMMMMMMMMMMMMMMMMMMNl .kMMMKc...    .oNMMMMMMMNOo:;,'..,:o0WMMMNx'.dNMMMMMMMMMMMMMMMMMMMMMKo. .oKWMM    //
//    MMMMMMMMMMMMMMMMMMMk. lNMMX: .dc     .xMMMMMMNl..,:'      .:OWMMMK;.oWMMMMMMMMMMMMMMMMMMMMMMXd, .cOW    //
//    MMMMMMMMMMMMMMMMMMN: '0MMWo .xx.      dMMMMMMW0kOd:.        .dWMMMO..OMMMMMMMMMMMMMMMMMMMMMMMMNk; .o    //
//    MMMMMMMMMMMMMMMMMM0' cNMWx. lx.      .kMMW0dOWMXl.           .xWMMWl lWMMMMMMMMMMMMMMMMMMMMMMMMMNl .    //
//    MMMMMMMMMMMMMMMMMWo .xMWx. :o.       ;XMMK, :NX:              ;XMMMk.,KMMMMMMMMMMMMMMMMMMMMMMMMMMk.     //
//    MMMMMMMMMMMMMMMMM0' :XNd. :l.        lWMMd..dXc               ;XMMM0'.OMMMMMMMMMMMMMMMMMMMMMMMMMMd.     //
//    MMMMMMMMMMMMMMMMNc .OWo..ok'        .OMMWc .Ok.              .dWMMMK,.kMMMMMMMMMMMMMMMMMMMMMMMMMNc .    //
//    MMMMMMMMMMMMMMMWx. oWX: .xd.       .dWMMWo .kx.             .oNMMMMK,.OMMMMMMMMMMMMMMMMMMMMMMMMWk. l    //
//    MMMMMMMMMMMMMMWx. :XMWO:...     .'cOWMMMMd .dO.            .xWMMMMM0''0MMMMMMMMMMMMMMMMMMMMMMMM0, ,K    //
//    MMMMMMMMMMMMMXl. cXMMMMWKkdddxk0KNMMMMMMMK; .;.           'kWMMMMMMO.,KMMMMMMMMMMMMMMMMMMMMMMMNl .kM    //
//    MMMMMMMMMMMM0; .dNMMMMMMMMMMMMMMMMMMMMMMMMXxc,..       .;dXMMMMMMMMk.;KMMMMMMMMMMMMMMMMMMMMMMM0' cNM    //
//    MMMMMMMMMMMO' 'OWMMW0oc:clox0NWMMMMMMMMMMMMMMWX0OkkkkkOXWMMMMMMMMMMk.,KMMMMMMMMMMMMMMMMMMMMMMMd..xMM    //
//    MMMMMMMMMMK; '0MMMWk. ''     .:dKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0'.OMMMMMMMMMMMMMMMMMMMMMMX: '0MM    //
//    MMMMMMMMMMO. lWMMMX; ,Oc        .kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo.,kKNWMMMMMMMMMMMMMMMMMWd. oWMM    //
//    MMMMMMMMMMX: .OWMMO. lo.         ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk:,,,;cdOXWMMMMMMMMMMMNd. cXMMM    //
//    MMMMMMMMMMMK, ,KMWl .xc          cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKOdl;,,;cx0NMMMMMW0: .lXMMMM    //
//    MMMMMMMMMMMWo .kMk. ck'         ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOdlcccoxOXWWN0xc,',cxKKkc. ,kWMMMMM    //
//    MMMMMMMMMMXo. :KK, ;O:        .oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0l,';lodoc;..,cdONWKc.  ....:xNMMMMMMM    //
//    MMMMMMMWKo. 'dXMk. ox.      .c0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO..oKWMMMMWO..cl;',;. .coodkXWMMMMMMMMM    //
//    MMMMMMKl. 'dXMMMX: ..    .;dKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx..xWMMMMMWk..kWMWK:  ;KMMMMMMMMMMMMMMMM    //
//    MMMMNd. 'xNMMMMMMNkc,,;lxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKx,.:0WMMMMMWx.'OWMMXl. :KMMMMMMMMMMMMMMMMM    //
//    MMWO, .oXMMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo.'cOWMMMMMMWd.,0MMMXc .dNMMMMMMMMMMMMMMMMMM    //
//    MNo.  'cd0K0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo :XMMMMMMMMMx.,0MMMMk. lWMMMMMMMMMMMMMMMMMMM    //
//    K:   ,dl..;:,,ccoO0kk0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWc oMMMMMMMMMN: dMMMMMd .xMMMMMMMMMMMMMMMMMMMM    //
//    ;   cX0;'d0o';od,..;:;;xNXXWMMMMMMMMMMMMMMMMMMMMMMMMMMWc oMMMMMMMMMK,.kMMMMMo .kMMMMMMMMMMMMMMMMMMMM    //
//      ..:o''OKc.dNW0,'xWMNc.,''cllldO0kxxk0kxO0xooddlll:oXWc oMMMMMWNXOc.:XMMMMWo .kMMMMMMMMMMMMMMMMMMMM    //
//     .o; . .;' ;0Xd';0WMMWl.c;.lO0kc..;oo,.:o;.'d:  c0K:'ON: :xolc:;,,,;oXMMMMMMo .kMMMMMMMMMMMMMMMMMMMM    //
//    ..,.:O,.cc. ..  ;lood:,xK;:NMMMk.'0MK;;XMd.lNd. :kx,'OO' .;clodkO0XWMMMMMMMMd..xMMMMMMMMMMMMMMMMMMMM    //
//    :   c0;,KMl.dkxddd;  ;0W0'cWMMNc ;KXl ,dd' .;.  .;:'.'',dXWMMMMMMMMMMMMMMMMMx. dMMMMMMMMMMMMMMMMMMMM    //
//    O.  .c.'0Mx'xMMMM0,.oNMMO.;XMNl   ..  .;:..lOO, oWMx.:ONMMMMMMMMMMMMMMMMMMMWo .kMMMMMMMMMMMMMMMMMMMM    //
//    Wd. .:;.,l;.;XMWO'.xWMMM0'.xXc.:xdd:..OMWc.xMK,.;ll;:KMMMMMMMMMMMMMMMMMMMMMK, ;KMMMMMMMMMMMMMMMMMMMM    //
//    MNo..oX0xdxo'cOl.'OWMMMMK, ., ,KMMMk..xMK;.;c;:O0kxOXMMMMMMMMMMMMMMMMMMMMMX: .kMMMMMMMMMMMMMMMMMMMMM    //
//    MMNl .dWMMMW0lcoc,lk0XNNK;.:o';KMW0:',;o:;k0k0NMMMMMMMMMMMMMMMMMMMMMMMMMM0; .kWMMMMMMMMMMMMMMMMMMMMM    //
//    MMMXc .xWMMMMMMMWKdllllllcxNWOccllcoKNOxkXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk. ,OWMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMXc .oNMMMMMMMMMMMWWWWMMMMMWXKXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl. cKMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMNo. :0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXx' .xNMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMWk, .cONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNKK0000OOOOkkkdc. .lKMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMNx;..'coxO0KKXNWMMMMMMMMMMMMMMMMMMMWNKOdc;,'...............':xXMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMW0dc,.......',;;::ccccccccccccc::;'...':cldxkkOOO0000000XNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWXOkdlc;,...                 .':oONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract gwg is ERC1155Creator {
    constructor() ERC1155Creator("Get well Gordon", "gwg") {}
}