// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Derrick
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    ........................................................................................................................    //
//    ........................................................................................................................    //
//    ...         .;ll,.            .':oo'  'loodddool;;ldoo::ll,  .:ooloc:oooc.  'lodl;ldl;co:cl'.,oc.                    ...    //
//    ...          'dK0o.            ;0WWo  .dXNMMMMWXoxNWW0xOXK;  .xNNXXkkNWW0,  ,ONMXdkWNddXOkK:.kXc                     ...    //
//    ...           .dKXKc.         .xWMMx.  :KWWMWWNOlOMMNkx0X0'  .kNWNNkkWNNNl  .lKWWOdKWOo0N00d:Ox.                     ...    //
//    ...            ;0KXKd.       .oXMMWo   :XMMMMXOooXMMKdkKN0'  .kNWWNkkNWNWO'  .oXWNxxXNxdKNKKO0o                      ...    //
//    ...            ,0XKNNd.     .xNMMMX;   lNWMMMNOlxWMMOdOKNK,  .xNWWW0xKWWMWo.  .lKWXdxXXddKWNWWo                      ...    //
//    ...            cXXXWMx.    ,OWMMMWd.  .kNNWMMW0lkMMMOd0KWNl  .lKWMMNxkNMMMNl   .cKWXdxNXddKNNWk.                     ...    //
//    ...           .xXKNMK:   .cKWMMMWx.   lXXXMMMW0lOMMWkd0KWMO'  ;ONWMMKdOWMMMXl.   ;OWXddXXxd0NWX:                     ...    //
//    ...           ;OKXN0;   'dXMMMWKl.   :KXkKMMMMKlkMMWkd0KNMWx;..dKNMMWKdkNMMMNo.   ,kNXddXNxo0NWO'                    ...    //
//    ...           c0KKo.  .;OWMMWKo.   .lKM0xKWMMMNxkWMMOd0KNMMWNx',xXWMMMXdxKWMMWk'   'xNXxdKXxo0NWx.                   ...    //
//    ...           ;Ok;   .lKWMW0c.   .:xXWM0xKNMMMMX0XMM0xO0XWMMMWO:;xXWMMMNkdONWMW0:.  .dXNxoKXxo0NNo.                  ...    //
//    ...           .::.  .dXWMNd.   .:x0XWMM0x0KNMMMMNNWMNkk00XWMMMWXxcdXWMMWW0dkKNWMNx'  .oXNxoKXdoKNXc                  ...    //
//    ...                .oXWMNo.   ,xKXNWMMNkdO0KNWMMMMMMMXOO00XWMMMMWKdd0NWMMWKxd0NWMW0:  .dXNdoX0oxXWk.                 ...    //
//    ...                ;0WMMO.  .o0XXNWMMNNKxx00KXNWWNNNWMNK00KXNWMMMMN0xOXWWWWNkdOXWMWKl. .xNXoxNxl0WO'                 ...    //
//    ...               .dNMMMx. 'xKXXXWMMMNXNXKXK00KKXNNNNWMWK000KXNWMMMMX0KKXNWMWOoONWWNKo. ;0WOlO0lxXd. ,;.             ...    //
//    ...               .kWMMMk..o0KXXNMMMMWXXNWWNX0O000KXXNWWWNK0K0KXWMMMMMWNK0KXNWko0NWMMNc .xWNod0ldk' .xk.             ...    //
//    ...               .kWMMMX:.o0KKXNMMMMMWXXXNWMN0OOO000KKXNN0xkO0KKNWMMMWNNXK0KNNxdKWMWWO..oNMxokodc  .dXd.            ...    //
//    ...               .oNMMMMK:,x00KNMMMMMMW0OXWWMNkc:cllloodkkl;:lllldONMWK0XKkOKN0oxNWWW0,.dWMxlolOo..'dNWx.           ...    //
//    ...              .;lkWMMMMXd:oO0KNWMMMWMKcl0XKo;coooollcc:c;';odlc;,okdoodkOO0XWxoKWMMO',0WNd:cx00OkOXWM0,           ...    //
//    ...               ckxKWMMMMW0xdk0KXWWNKXNd,:lc:lxxxxxxxxxxdlcldxxxdolldxdoclxOXNxo0NMNo;kNWk;;x0KXXNWWW0:            ...    //
//    ...               'kKKNWMMMMWWX0000KKNXKKkc,:ldxxxxxxxxxxxxxxxxxxxxdolcloxdc,lKNdoKWWklONWO;,d0KXK0kxo:.             ...    //
//    ...                'dKKKNWMMMWNXXK000KXXx:;;oxxxxxxxxxxxxxddxxdodoc::clloxxd,:K0lxXWXOKNXx:cx0Od;'.                  ...    //
//    ...                 .;oxkKNMMMWNXXK0O0K0l,:oxxxxxxxxxxxxxxlclccodllddxxxxxxd;lxldKNWWWWOccxkOx'                      ...    //
//    ...                  .;clok0XWMMWNXKxokx;;oxxoclclddooloxxoc:;:oddxxxxxxxxxl,;':OXNWWKo,l00xo'                       ...    //
//    ...                   :dcldooONNNMWWNOd:,:ddllllccllodc;oxxxdddxdoddocclodxoc:,l00XNklodOKXk:.                       ...    //
//    ...                   'dxO0ocooldKNMWWXd,:dxdl;'..'.,::cdxxxdxxo:;;'....';ldxl,lO0XklkX0x00o,                        ...    //
//    ...                    ;ddxlcxdllooxXWWK:,c:,';oo:'....;oxxxxxo;'.,lo:.....;lc',oK0dx0kddxdc.                        ...    //
//    ...         .',,'..... .,::::ldxkkoccdXK:..'cx00xoc,'...:dxxxxc':dOOdll;''....'l0Xdooccc:cc..     ....',;;'          ...    //
//    ...          .,coddocc::;;,,;;;::cc:;'cd:,,cKWMWOlc,.,',oxxxxxockWMNklc;';c;;;,;dxc:::;;,,''',;;:clloxdo:'.          ...    //
//    ...             .';:cldxdoc;,;::::ccc;',c:,;lONMMN0Oxl:cdxxxxxxlcxXWMWX0Oxlcol,;:ccccc::ccc:;cdxo:;::,..             ...    //
//    ...                 ..';cooollddooll:;,:c;,,,:odxxxdlcodxxxxxxxxocldxxxxocclccddl;:lloddxxxdlc:;....                 ...    //
//    ...                      ..'''codxxolc:;,,,,:ccloloodxxxxxxxxxxxxxxdoooodocoollc:coooddoc:;'..                       ...    //
//    ...                            ..,,''';:;;,colldxxxxxxxdlclccldxxxxxxxxxxxddo:,;c;''.'...                            ...    //
//    ...                                 ..':;;;:dxxxxxxxxxxdlc::cldxxxxxxxxxxxxd:,;;'...                                 ...    //
//    ...                                  ..,;do;lxdddddddddoooooooddoddoooc:cdxl,;oddc.                                  ...    //
//    ...                                   .:dKk;:oo:,,;oOOOO00OOOOOOOOOOl'':oxo;:x0Oxc.                                  ...    //
//    ...                                   .xNNXl.;odoc:d0XWMMMMMMMMMMWNOoldxdl,..',,.                                    ...    //
//    ...                                    .;:,.  .;odxdddxkkOOOOOOkkkdodxdl;.                                           ...    //
//    ...                                             .,coxxxdddooooodddxxdl,.                                             ...    //
//    ...                                                .,codxxxxxxxxxdl:'.                                               ...    //
//    ...                                                 .';:cloddddlc:,.                                                 ...    //
//    ...                                                 'clccc:::::::cl;.                                                ...    //
//    ...                                                 ckkxxdllclodkOXd.                                                ...    //
//    ...                                                 :0NNNXK00KXWMMNo.  ',.                                           ...    //
//    ...                                           .'..':lx0XXNNNMMMMMXdlxxoxo. .'.                                       ...    //
//    ...                                       ... ;ddx0KK00KXNxd0XMMWKkKWWWX0dcol.  ..                                   ...    //
//    ...                                    .. 'oodOXNNWWMMMMMNl.,xMMMMMMMMMMMWNKOo::o'   ..                              ...    //
//    ...                           '.  ;,  .cdokKXXNMMMMMMMMMWk.  :XMMMMMMMMMMMMMWXKOdc;,:l,  .:,                         ...    //
//    ...                         .;dl;cdo:lxk0XNWWNWMMMMMMMMMO'   'OWMMMMMMMMMMMMMMWNK0KXKOOOkOOkxo,                      ...    //
//    ...                       .:xOKXNNXXXXNNNWMMMMMMMMMMMMW0,    .cdKWMMMMMMMMMMMMMMMMMMMMMMMMMMWMO.                     ...    //
//    ...                       'kKXWMMMMMMMMMMMMMMMMMMMMMMM0,     ...cdlxKWMMMMMMMMMMMMMMMMMMMMMMWM0'                     ...    //
//    ...                       .dXXNMMMMMMMMMMMMMMMMMMMMMMK:         'l. .c0WMMMMMMMMMMMMMMMMMMMMMMO.                     ...    //
//    ...                        ;0NWMMMMMMMMMMMMMMMMMMMNXNo          .c'   .oXMMMMMMMMMMMMMMNNWMMMWd.                     ...    //
//    ...                        .oKWMMMMMWMMMMMMMMMMMMWxok, ..    .  ..      cNMMMMMMMMMMMWKxONMMMNc                      ...    //
//    ...                         'kNWMMXkxKWMMMMMMMMMWk.;l. .. .;:;:;. .     .kWWMMMMMMMMW0ddKNNWM0'                      ...    //
//    ...                          :0NWMXd:xXNWMMMMMMM0, ..    .cl:,:d,       .codNMMMMMMWOokNWWWMWo                       ...    //
//    ...                          .oKNWWNOdkKXNWMMMMWo         '::;:;.   ..     '0MMMMMMNxxKNMMMM0,                       ...    //
//    ...                           'ldxkkko:ldodxkkkx,      ...  ...     ''.    'dkkkkkkd:ldxkkkkc.                       ...    //
//    ........................................................................................................................    //
//    ........................................................................................................................    //
//    ........................................................................................................................    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DRRCK is ERC721Creator {
    constructor() ERC721Creator("Derrick", "DRRCK") {}
}