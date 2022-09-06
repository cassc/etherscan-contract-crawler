// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 24's Scratches
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNXXXXXXXXXXNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNX0Oxdolc:;;,'''''''''',,;::clodkOKXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0kdl:,....,,;;;;;;;;,;;;;;;;;;,,.   ....';coxOKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0xl:,.........cKXXXXXNNXKXXXXXXXXXXX0;.......... ...;cdOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNOdc,............. :0d::::::oxl:::::::::o0c..................':okKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxc,................. :0: . .;oxo.       . ,0o.......................:oONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0d:..................... c0; .:kXXx:. .   ... ;0l..........................,lONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKx:........................ c0; .;kOl';, ....... ;0l.............................,oONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOc'.......................... l0, ......cc. ...... ;0l................................;xXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMXx;............................. lO, . .. .lo. ...... ;0l .................................'o0WMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMXd,................................oO' .    .ox. ...... ;0l ....................................c0WMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMXd,.................... .............oO' .... .oO' ...... ;0l ............    ...','................c0WMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMNk,......................   .........  oO' ......oK; ...... ;0c ...    ...,;clllcc:;;'..................lKMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMW0:....................................  oO' ... . cKc ...    'l;.',:cloxxddddlc;'..   ....................'xNMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMXd'..................................... .oO' .  .,':Xd'',;:cloxxxxxxxdlc:,...   .............................:0WMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMW0:.............................. ..........:o:;ccld000WXkxkkxdocll;....   ......................................'xNMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWx'............................... .cdddddddodxxdx0NXXkoXO,....   ,k: ..............................................cXMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMNo....................... ......... .............  .:kNd;0O'  .... ;O: ...........  .. ...............................;0MMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMXl........................  ...................co. .. .x0lOK,  . .. ;O: ..........      ................................,OWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMXc..................... ........  .. ....      .dk. .  .dXlxK;  .  . ;O: ...........   .................................. 'OWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMKc..................................  ...       .dk.    .oXldX:  .... ;O: ..........  ............... ..................... 'OWMMMMMMMMMMM    //
//    MMMMMMMMMMMK:...................... ..    ..        .     . .dx. .   :XdoXc     . ;O: ....  ......................... .................. ,0MMMMMMMMMMM    //
//    MMMMMMMMMMNl..................  ....... ..          ..      .xd.  .:dkNx:d;  .  . ;O; .    .........................   ...................:KMMMMMMMMMM    //
//    MMMMMMMMMWd...........................  ......      ..      .xd.  .cx0WKdlc:;.  . :O; .   ..... ...............        .   ................lNMMMMMMMMM    //
//    MMMMMMMMMO,....................................           . .xd.    'dXKl;:ccol'. :k, ..  ........... ........           ...................xWMMMMMMMM    //
//    MMMMMMMMXc.................................          .      .xo.  .;ko;'.    .cd; :d' .     .............. ...           ...................;KMMMMMMMM    //
//    MMMMMMMMk........................   ..  ..   .              .xo.  ;0o. .      .:d,:k, .     ............                .....................oNMMMMMMM    //
//    MMMMMMMXc.........................  ..... .                 .xd. .xO' .        .llck; .      .  .  ........             .....................'OMMMMMMM    //
//    MMMMMMMO'..........................  .......                .xo. ;Kx.         . ,dxk; .       ..... ...   .   ..    .   ......................oWMMMMMM    //
//    MMMMMMWo............................ .....                  .xo  cNd.           .o0k; .        ..  .        ..   ..... ... .... ..............;KMMMMMM    //
//    MMMMMMX:................................                    .xo  lWx.  ......   .lKO, .         .      .  .....  ....  ..... ..................kMMMMMM    //
//    MMMMMM0,...............................                     .xl  cNk..:k0kxko'  .cXO, .        ..      ..  .....             ..................dMMMMMM    //
//    MMMMMMk.................................                    .xl  ,KK;'0MKd0WWd. .cOk,              .......  ...               .... ............lWMMMMM    //
//    MMMMMMx.................. .   .......      ....           . 'Ol  .kWo.l0KKK0x,. 'cox,             ..... ......                 ... ............cNMMMMM    //
//    MMMMMMx..............................      ....             ,Oc   cNK; .''... ..;.:x, .       .......   ....   ..           .   ...............:XMMMMM    //
//    MMMMMMx..............................      .              . ,Oc . 'OWd. .     ... :d' .     ......   .   ..            .    .  ................:XMMMMM    //
//    MMMMMMx..............................                     . ,Oc   .cN0,         . :d' . .   ....   ........ ..         ..      ................cXMMMMM    //
//    MMMMMMO'................  .............                   . .;.    .xWd.        . :d' .    ...';;,. ...........            ..    ..............lNMMMMM    //
//    MMMMMM0,.............................               .....,;::cclolc:oXK; .  ..    ':'.,:cldxdol:,.. .........              ..  ................dWMMMMM    //
//    MMMMMMXc.........................                   ,ddddxxxxdoc:;cxcxWd. ....,:codkOOOkxo:,..   .   ........         ....................... .kMMMMMM    //
//    MMMMMMWd.........................                   ....... .:'   :0oxWKddkO0000Odoc;'..    .... .   .........  ...  ........................ ;KMMMMMM    //
//    MMMMMMM0,.........................                        . ,k: .ckNWWMM0kOxl,'.. ... .       ...  ..  ..       .....  .......................oWMMMMMM    //
//    MMMMMMMWd..........    ....   ....                          ;k; .cddxKMWl:dl' ... ;o. .   .    ...............    ....   .. ................ 'OMMMMMMM    //
//    MMMMMMMMK;........... .....                                 ;k;     .dWX:lOd, . . ;o. .         ......''','''.. . ....... ...................lNMMMMMMM    //
//    MMMMMMMMWd. .........  ....           ..                    ,o'     .OMNodXO: ....,;',;::cllodxxkkxxxxddolc;,.. . ......................... 'OMMMMMMMM    //
//    MMMMMMMMMX:.............  .             ...            .;:::cllcclloxXMNOKWN0kOkkkkkxkkkxxdolcc:;,'.....      .. ......................... .dWMMMMMMMM    //
//    MMMMMMMMMMO,........ ..   ..             ..           .;dxOO0KXXNWMMMWNXKNMWO::;,'......         .............. ...........................lNMMMMMMMMM    //
//    MMMMMMMMMMWx........              ....                    .....',;lx0XWNKNMWd.    ,:. .       . .  ..  ...................................cXMMMMMMMMMM    //
//    MMMMMMMMMMMNo..........            ....                     ,c. .c0XNKo;,kMMd.    :o. .        .....  ..   ..............................;KMMMMMMMMMMM    //
//    MMMMMMMMMMMMNl...........           ..                    . :x' .,oxOKKx;xMMx.    co.         .....         ............................;0MMMMMMMMMMMM    //
//    MMMMMMMMMMMMMXl...........                                  ck'    .oXXd,dMMx. .  co.            .. ..      ....    ...................;0MMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMNo............                                oO'   .lXXNXllWMk.    co. .......    ......    ...        .. .............;0MMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMNx'............                              oO'    .,:0Nc;XMO.  . co. .......     ....     .          ... ...........cKMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWO,...........                             .oO'    . 'ONc.o0d.    :l.  ....         .....             ..............oNMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMKc..........                             .dO.    . .kNc ...     :o. . ......        ...       .         ........;OWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMNx'........                             .dk.    . .xNc         :l. .     ....       .. .       . ...     .....lXMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMKl.......                   ..        .dk.    . .xNl         :l. ..   .           .....   ......... .. ...;OWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWO:.......                ..         .dx.      .xWl         ;c.      ..   ...    ...      .............'dXMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMNk;.....                   ..   .. .dx.      .xWl.        ;c. ... ................. ....... .......'lKWMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMNk;....                 ....  .. .dx.      .dWl.        ;c. ............................    . .'oKWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMNkc....      ...   ....      . .dx. .  . .oNl     .;:.:c. ....    .. ... ... ............ .,dKWMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0o,. ..   ...    ...      . .dx. .     cO;   .ckKk,:c........     ............  ... ..:kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNkc'. .    ...  ..        .dx. .  .. ... ..;OX0l.::..........  ........ ..      .;dKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkc'. ....   .         .dO;,,;,,,,,,,,;;;cdl:cxl.......................  ..;d0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXko;.. ...          .:OOO00OOOOOOOOO00OOO0K0l.......................'cxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxl;..   .    ...'looolllllllllllllllloo;...................,cdONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKOdc;'.. ....                      ................,:ox0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0xol:,'...      . ....................,;codOKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNX0Okdolcc:;;,,,,,,,;;;:cclodxk0KXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWNNNNNNNNWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract M24S is ERC721Creator {
    constructor() ERC721Creator("24's Scratches", "M24S") {}
}