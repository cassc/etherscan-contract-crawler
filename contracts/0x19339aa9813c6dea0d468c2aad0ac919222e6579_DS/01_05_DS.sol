// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dataspectrum
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                         //
//                                                                                         //
//    D)dddd             t)              V)    vv         l)L                     t)       //
//    D)   dd          t)tTTT            V)    vv          l)                   t)tTTT     //
//    D)    dd a)AAAA    t)   a)AAAA     V)    vv e)EEEEE  l)  v)    VV e)EEEEE   t)       //
//    D)    dd  a)AAA    t)    a)AAA      V)  vv  e)EEEE   l)   v)  VV  e)EEEE    t)       //
//    D)    dd a)   A    t)   a)   A       V)vv   e)       l)    v)VV   e)        t)       //
//    D)ddddd   a)AAAA   t)T   a)AAAA       V)     e)EEEE l)LL    v)     e)EEEE   t)T      //
//                                                                                         //
//                                                                                         //
//    00000OOO0KKxlodclddooodxxxkOO0KKXXK0Oxlcccok0KKK0OO0OkOOOO000000000KKK0OO0000000     //
//    KkkOOO0KKOkkxdddxkkk000KKKKOxolc;,'.. ..   .':cloxO0KKXKKKKK0O0KKKKK0xokKKKKKXXX     //
//    Oxxkkkk0K000OOO00KKKK0koc,..           ..    .   ..',cldk0XXK0O00KKK0OkO000O0000     //
//    OxdxOOkOK0K000KKXKkl;..                ..               .';lx0KKKKKK000O00O0000K     //
//    0OkO0000OOKKKX0xc'.       ..           .         ..          .:dOKKK000OOOOOOO0X     //
//    00OOKKK0KKKKkc'..                     ..                        .:d0XKOOOkkkkO0K     //
//    XX0O0000KKx;.   ..   ..               ..    ..        ..           'o0K0OOkkOO0K     //
//    0OkOKKKKx;...       ...               ...  ...        ..             'd0KK0KK0KK     //
//    00O0KK0c.  ..                    .......     ...                      .:OKK00KOk     //
//    0OO0Kx,                           ......   ..  ....                     .oOOOK0k     //
//    K0KKd.                            .......  ...                            ;OXXK0     //
//    XXKo.   ..               .'.     ...  ....  ....                           ,kX0k     //
//    XKd.           ..    .   ...    ......';,'.........         .          ..   ,OK0     //
//    Xk'             .       ...   .....';lloddlc:,'........                ..    :0X     //
//    K:                      .  ......;coxkOkkOOOxdc;'.......                     .dX     //
//    x.                      ......,:lddkkOOOkkOOOkxoc;'......                     ;K     //
//    l                  .    . ..';oxkO0Okk0000OxOOOkxo:'.......                   .k     //
//    ;                        ..,:oxkOO0kcoOO00l:k0OOOko;........                  .o     //
//    ,   .               .   ..':dddddcc:.';,:c,.oOOOOxol;.......       .           :     //
//    '                  ..   .':lllc:;...        .'cooddoc,.......   ....           ,     //
//    ,                  .. ...,cc;''....  .....    ...cool;....'..   .,.            '     //
//    ;                 ...   .;:c:,... .           ...;lol;....'..   ..   .         ,     //
//    :                 ...   .;cc;'..  .            ..,loc,....'..                  ;     //
//    o.               ..... ..'::,.........        ..,:ll;.....'..                  l     //
//    k'             .  ..... ...;:;,'.''.........',::cl:,.....,'.         ..       .k     //
//    Kl.    .            ....   ..'::;::,'',,'';ccclc:,'.....,'.          ..       lK     //
//    XO;                   ..........,::;:::::cllc:;'....'..'..       .           ,OO     //
//    KXx.          .         .....   ...'''..'.''............        ..          'kKx     //
//    KKKd.        ...               ..  ....    .....'''....     .              'kXKK     //
//    XXXKd.                        ..... ...   .......... ..     ..            'kXK00     //
//    000KKx'                    ....   .         .    ...                     ;OK0000     //
//    kkkk0Kk;.                      ....         . ....                     .l0Kdlxdx     //
//    OOOO0KK0o'                       .. .. ..  ..                         ;x000kxkkO     //
//    00000000OOl'     .                . ..     .                        ,dO0kkK0kkO0     //
//    OO00OOOOO00Oo'   .         .. .. .         ...          .     .. .;dKKOxxxkOxxkk     //
//    000000000OO0X0d;.                .      ..        ..   ...     .:kKXXKOO0kx0OkOk     //
//    XXXKK000O0KKKKK0xl;..                        ....          .,cdO0O00KX0O0OkOOOOk     //
//    XK0OOOOOOO0KKK00OO0Oxo:,..            ....    ..     ..';cokKXKx;;::kXOoxkO0K0kO     //
//    XXXKKKKKKK0OOOOOOO00KK0Okdlc;;,,'..   .........'';:lloxOKKOOKKKxc,,ckKKdoxO00OO0     //
//    XXXXXXXXXXKOkOkkOkk0XKOO0O000000Oxol:;:llolcldkOKKXKo::dK0xk0KKx:,';kXKOO0KK000K     //
//                                                                                         //
//                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////


contract DS is ERC721Creator {
    constructor() ERC721Creator("Dataspectrum", "DS") {}
}