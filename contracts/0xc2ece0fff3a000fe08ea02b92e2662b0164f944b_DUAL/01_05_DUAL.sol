// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Livre de la Dualité
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWNXXXXXXXXXXXXXXXXXXKKKKXXXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK000KKNMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMKc'..............................................................'xNMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWl                                                                 .OMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWc    .cllllllllcccc'      ..';:cccc::;,'.       'llooooollool;    .OMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWc    dMMMMMMMMMMNkc. .,cdkKXKkolc::cokKXK0xo:'. .ckNMMMMMMMMMK,   .kMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWc    dMMMMMMMWOl'..cxKNMMMMNx:'     ':dXMMMMWN0d;. 'l0WMMMMMMK,   .kMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWc    dMMMMMNk;..;xKKxc;oNMMNOo,     ,lkXMMWx;:lkXKd, .:OWMMMMK,   .kMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWl    dMMMWO; .c0N0c.   .OWk,           .oXN:    ,xNNk; .cKMMMK,   .kMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWl    dMMXl. ;OWMXo'''. ,KXl,,,.     .',,;OWd..,,,c0MMNk, .xNMK,   .kMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWc    dM0; .dXXKWMWN0d, ;KMWN0o'     .cxXWMWd.'lkXWMMX0NXo. cXK,   .OMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWc    ck' 'O0l.,0WKc.   .OWO;.          'dXWc    'dNMd.'dKx. ,c.   .OMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWc       ,0k.  .Ok.     :Kx.     ...      ;Kx.     :Xo   :Kk.      .OMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWc      ,0X;   .c,    ;kNK;    'dKXKOl.    dWXd.   .ll   .xWx.     .OMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMNc     .kMWOdddOKOxxxxOOKN0xxxOXMWNNWWKkkkkXNOkxxkkOKXOOO0NMNl     .OMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWc     cNMMMWOloXMWOc'. '0MMWOo:;,.,odlxXWMMk. .'l0WMOcoKWMMM0'    .OMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWc    .k0xXKc. .OXc.    .kWO;       ..  .dNMx.    .lXd  .dN0d0c    .OMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWc    .l'.l;   .c;     'dXk.           .  oWXd,     ..    :; ..    .OMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWc                    :XMWl         'xOKo.'0MMN:          .;.      .OMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWc     .              ;KMWl         'xOXO..OMW0,          .'       .kMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWc    ;x'.dc   .l:     .lKO'          .;' ;KK:.     ;,   .oc ;:    .kMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWc    '00kXNo. .ONd.    .xM0c.          'oKMk.    .dNx. ,kWKkXo    .kMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWl    .dMMMMWKodXMMKd;...kMMWKxlcc;;clokNMMM0;.';oKWMKdkNMMMMX;    .OMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWl     ,KMW0xddkX0dddxO0KN0dddd0WMMMMW0doodONXKOdoook0doloOWWd.    .OMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWc      lNWl   .do    .oKNc    .ck00kc.    cXKo.    cl.   cNO'     .kMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWc      .dWK;  .xXc     .k0;      ..      ,0O.     :Kx.  :K0,      .kMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWc    .' .oNXd''kMNx,    dMXd'          .oXMx.   ,xXMO,,xX0, ':.   .kMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWc    oXl  :KMNKNMMMNOdcl0MMWXkl'    'lkXWMMKlcdOXWMMWXNNx. ;KK,   .kMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMNc    dMNx. .xNMMM0c;;;;:OWk;,,,.    .,,;;kW0c,,,,;kWMW0: .oXMK,   .kMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWc    dMMW0:. ,xNMNx,    oMXd'          .oKMk.   .oXW0c. ;OWMMK,   .kMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWc    dMMMMWk;  ,dKWNOo:c0MMMNOo,    'lkXMMMKocokXNk:. ,kNMMMMK,   .kMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWc    dMMMMMMNO:. .:dKWMMMMMMKo;.    .;l0WMMMMWXOl,..:kNMMMMMMK,   .kMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWl    dMMMMMMMMWKd;. .,lxOKNMWKkolcccox0NNX0xo:. .;dKWMMMMMMMMK,   .kMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWl    ,dxxxxxxxxkkx:.     .';:cloooooolc;'.     .:xxxxxxdxxxddc.   .kMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWc                                                                 .kMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMk'                                                               .lXMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMXOkkkkkkkkkkkkkOOkkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOKWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DUAL is ERC721Creator {
    constructor() ERC721Creator(unicode"Livre de la Dualité", "DUAL") {}
}