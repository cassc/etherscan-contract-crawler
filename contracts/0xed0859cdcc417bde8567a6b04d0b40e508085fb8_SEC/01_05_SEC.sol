// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Web3 Security Token
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                              ......'',,,,..     .........                                                                      //
//                                                                                                     ..,,;:clloodxxkkOOOOOkd:'.,cdxxkxxxdolc:;,'...                                                             //
//    .                                                                                      ...'''...'cxkkkkOOkkkxxdoollldxO00kkO0Okxdddxxkkkkkkxdolc;'.                                                         //
//    c'.                                                                               ..';:ldxxxkxl;cdO0Oxc;,'....... .cOXXNNNNNXK0kc.....',:clodxkOOxc....'...                                                 //
//    Ol'.                                                                         ..';cldxkkxdoox0X0kxk000Ox:.         .oKKKXXXXK000Kx'         .'cdk0Oo;:oxkxol;'..                                             //
//    NOl'                                                                     ..;codxkkxdoc;'.,ok0KKOkkkkxxOO;          ;k00KXXKOkO0Ol.         .:xOO0KKKK0OkkOOOkdl:'.                                          //
//    NXOc.                                                                   .;oxxxdlc;'..    'x0OOOxdddddxkx,  ...'',,,;cx000OkO00x:...        .oOOkkO0XXXKOdc:lxOOOkdc,..                                      //
//    NNKo,.                                                            ..,;::coxdl;'.         .:dkOOxolodxxxocldk0KXXKK00OOOxo:cx0KOxdooolc:;,'.'lkxdodxO0KXNO;  .':oxOOOxl;.                                    //
//    XNXxoc,.                                                       .':odxxxdoodxxxdc.         .'cdkOxooxkO0000KXWWWWNKOxdlc;. .,lkO000K0OOOOkkxddxxooodk0KKk:.     ..;lxOOko;.                                  //
//    0K0kOOko;.                                                  ..;lxkkdlldxdxxxxkO0o.    ..;coxkOOkl,,:ccll:cxKNNNNKkc'..      .':odxdo:;;clddxddooodxkkd:.          .,lkOOx;.                                 //
//    OOxccoO0ko;.                                              .':oxkdl,..cOKOxdddxOOo;,:ldk0KKK00Okdl:,'....':d0XNNXKko:;'..     .'lxdc,.  ..',,'...';:lxxo:'.      .:dxkO00Odc,..                              //
//    0Kk:..;oO0kl,.                                          .,ldkxo:..   ,dOOOkkOKNXKXNNWWNXKKKKKKXKKK0kkxddxOKXXK0OOOOOOkdc,.   .,lxxc'..,;:cc:,.. ..,:oxOOkdc'.  .dKXXKXNWWXOxdc'                             //
//    0Kk,   .;dOOxc.                                       .;lxkxl,.       ..,oOXNWMWWNNNNWNNNNNNNNX0kkkO0000KK0Odc,,;:clodxkd:.   .cxkdllodxxxxxxdl;.. ..';lxOOkd:';xKXXXKNWWKxxOOd:.                           //
//    oc'      .cx0Oo,.                                    .:dOxc'.          .:kNWMWNKkolldOXNNNXKXXXOo,.'',;;:;,..       ..cxkd;.  .':dxxxdl:;,,;coxdc'.    ..;ldkOxxkOkkk0KKKx;,lk0Oo;.                         //
//              .,oO0d:.                                   'lOOl,....      .:xKNWWNKd,.   .'coddlcoOXXk;.                  .cxOd;.    ..,,,..     .,cxxl'.      ..,cdxxdoox0KKOc. .;dO0kl'.                       //
//               .'lOOx:.                                  .ckOxoldxo,.  .:x0KKNWN0o'         .. .:kXXO:.                 .;x0Oo'                  .'cxxc'.....    .;ldxdocclo;.    .cx0Ox:.                      //
//    ;.     .,:llccdOOl'                                  .;dOOkxxkkd:,:x00kookXX0o'            'o0NKx,                 .;d00d;.          .';;;'.  .,lxxollllc:'.  .:dOOx;.         .,oO0kl.                     //
//    Oo'   'dKK00kxk0kc.                               ..,cdOKK0OdooodxkOxl,.,dKXXx'           .:kXXOc.        .;ldol:'.,d0Kkc.         .;oxkkxo;.  .'coooooodxo:.  .;oO0x:.         .;lxKO:.                    //
//    00kc..c0XX0Okk0Od;....                           .:dkOKKKKKOxddxxxo;.. .;xKXO:.     .':llccoOXX0c.       .lOXNNXOo;:kKX0dc,..    .,okOkxooc,.    .......;oxo:.  .'cx0Oo,.     ,okOkkXXxc;,..                //
//    lx00koox0XXKKXXKkdodxoc;..                     .,ok0kocldxkxdoolc;'.....cOXKo'     .;xKXXKKKXNNX0xl:;,.  ,kXX0Okd;.'lOKXXK0kd:.  .lOK0d;...             .cxxc'    .;oO0xc.   ,kXXKKNNKOOOOd:.               //
//    .,lxO00OOKNWWWNNXKOO000Odc,.                  .cx0Oo;.'cdxxxxkkxxxkkkkxdd0NKx,     .cONNKkddddxOKXXK0ko:':kXXx:..   .':ok0XXX0o'..cOKKx:.              .,lxd:.     .'cxOOd:..;ONXXXXK0kxxO0Oo;.             //
//      .';ldxxOXWWWWNN0kxkxdxO0xl,.              .,lO0kc.  'lk0KXXNNXXK000KKXXXNXO:.    .:OXXOc.....:kXNXK0xollkXNO:.       .:kKXX0o.  'lOKKOo,.          ..;oxxl,.       .,lxOOkooONWNXKK00x:;oO0x:.            //
//         ....,dKNNNNKOOOOo''cxOOxl,.           .;oO0d;.    'o0NWNKOxl:,,,;coxkxd:.      ,dKXKd,   .cOXXOxo::okKNXkc.       .;dOOxc.   'lOKX0x;.      .,:cloxkkdl::;;,..    .'cdxkkOXWWNNNX0c. .lO0xc.           //
//             'oO0XXK00KKx'   .:dOOxc,.        .;dOOd,.      ;xKXkc,..      ....         .:kXXOl. .;xKNKxolokKNNKx;.          ....    ,o0XKkl,.     .,lkOOkxdoodddddddoc,.......',;lOX0xol:'    .ck0kl'          //
//             'lk0Odoxxd:.      .:dOOxc'.     .,oO0d,       .;kKOc.                    ...,dKNKo' .;xKNXKKKXNXKOl'       ..          .;xXX0o,.      ,oO0kl;....''.',:odddool:,..  .;d00o.        .ck0kc.         //
//             .,oO0x:..          .'cx0Oo,.    'lO0d,.       'o0Kx;.                .,codddx0XXOc.  .;d0KKK0Oxo:'.     .,lddl,.        .lkKXKxc.    .:xKKx;.         ..;:clodxdl,.  .cx0Ol.        .ck0x:.        //
//               'lk0Oo;.        .'',:dOOl'   .:x0kc;:c:'.  'oOKk:.    ..,::;,..   .lkKXXXXXXXOl.     .';;;,'.        .:xKXNKd,...''.....,lOKX0d'    'lOKOdl:,.          ...,cxxl'   'ck0Ol.    .,;''l00o,.       //
//                .;oO0Oo;.   .:dkOkdldOOo'   .:k0kdk0KK0o,:x00x:.   .'ck0KKK0kl'..l0XXKOxddol;.                   .'cx0XNXKOo::okOOOxoc;;cxKXXk;     .:xO000Od,.           .,oxd:.   .ck00o' .ck00d:cOKx:.       //
//                  .:dO0Oo;. 'd0KK0OkO0kc.   .;xO0KKK0OkxdkKKx:.   .;d0XNXXXXXOo:lOXX0o,.           ......        ,d0XXKko:,,ckXNXXXXXXK0KXXX0l.     .;ok0KK0x;.            .cxxl,.   .cx00x:lO0KK0kkO0d,.       //
//                    .:dOKOo;,lkOOkO0XNKo,.   ,dKNNN0kdloxOxl,.    .ckKXXKkxOKXK0KXXKd'     .;cll:;:okOkdl:.     .:OXN0o,.  'dKNXOdodk0KKK0Od:.    .,oO0K0kdl,.            .,lxxl'     .;oO0Oxxxk0KXXKk:.        //
//                      .;dO0OdloxkOKXNNNKkl;;lkXWWWNKOkxxkxc'.     .,o0XKkc',lk0KKKOo,    .,d0XXXKKKXNNXKK0xc,,'..:OXN0l.   'dKXXOo;..,;;;,..     .;d0XKkc'.              .,lxxl,.      ..:dkxoox0XNNWXx,        //
//                        .;lxOOkOOOkxxk000Ok0NWWWNNXXKOkO00ko;.   .':xKXKx;.  .';:;'.     ,dKXX00KXNNKOk0XXXK000xclONN0l.   'd0XNXk:.            .ckKXXKd'                .;okdc'.         .cxddk0KNWWWNd.       //
//                          ..;clooc;'..,::lxKNKKXXXXXX0dcoOKKOd:;cx0KXNX0l.              .cOXXOl,;cddc''lxOXXXKXKOOKNKx;.   .,lxkkl'.            .;xKXXKx,         ..      .cdxdl:,'..    .,lkOkkk0XNWWNO;.      //
//                              ....       .cOKkxkKXXXXO:..,lkKXKKXNNXKXKOl'              .,dKX0d:.      ..,clccdOKKKOo,.       ...',;cllc;..       ':lol;.      .;lolc;'.   .;ldxkxdl;.  .ck00kddxkO000K0o'      //
//                                         .:k0kocldkkd;    .,dKWMWNkclOXKkc'....          .,lk0Kkl.            .,;:;'.          .;ok0KXXK0xc.                 .,oOKK00Oxl;.  .'cxOOkd:. .;xKKkc'.....'ck0kc.     //
//                                         .,d00d:....       .lKWMWKl.'oKXKOxxddl;.     ....';lkKKx;.                           .:kKXXK00KXXkc.        ...    .,d0K0xodk00xc.  .,lddl;.  .,o0K0d:.     'lO0o'     //
//                                          .:dOOd:.      .:dk0NWMWXd..'oOKXKKKK0xc.  .'lxkkkkO00kl'                            ,dKXXOl,:d0NKx;.    ..:odoc,..;dKX0d,.'lOK0d;.  .....     .'lk00k:.    .:xOx;.    //
//                                           .,lkOOd:.   .dKNXXNWWNKo.  .,cllldO0Od;...cx00Oxdol:,.            ...              ,xKNKx;..cOXNKxc,.',cx0XXX0xllxKXKx;. .,lddc'            ...;oOK0o.     ,oOkc.    //
//                                             .,lk0Od:..:0XK0KNWNKx;.       ..cdkkoccldOOxc'..              .;oxl,.';ldo:'.    .l0XX0o...lOXXXKOOkOKXXK0KXXKKXX0d;.    ....          .'codxkO0Kkc.     'okkc.    //
//                                               .,lk0Od:ckXXKXNNKkc.          .,ldxxxxxdl;.            .',,:lxOK0kkk0KKK0x:'..':d0XNKd,  .,lxO0KKKKK0xl:lkKXXKkc.                    'lOKK0Okxo:.      ,okx:.    //
//                                                 .,lk0Okk0KXNWXx:.             ..,;;,'..            .;oxkkkxdddkOOOxoox0KOxdxO0KXX0x:.     .',:ccc:,.. .':cc;.            ....      .ckKKOl,..       .:xko,.    //
//                                                   .,cdkkkkk0XKo'                     ....         .;okkdoc,...',,'...'cdkO00kxdol;.            ......               .';codxxdo:,.. .'lOK0o'   ..',,;cxkd:.     //
//                                                      ..''',ck0kl'.                ..,:cll:'       .;okxoc'.            .';:;'..               .,oxxxdl;.           ,dOKKXXXXXKKOxolclx0K0d,..':dxkkkkxo;.      //
//                                                            .:okOxl;...         ..,:oxxxkkx:.       .:oxkdc,..                                .:kXNNNXKOo,.        .:OXXKOxoooxOKKKKKKK0Od:. .:xOkdol:;..       //
//                                                             ..;ldxxdoc:;;,,,;;:lodxxoccokx:.       ..;lodxdocc::;'.              .',,..      'dKNNK0KXXKx,         ,dKX0x:. ..':lddddoc;.   .;dOkl;..          //
//                                                                .';clodddddddddddol:,..;oko;.......',;::::clooddxxo;.           .:dO0Oko;.   .;xXNXkld0XXO:.    ....,o0XXOc.      .....       .:xOxc.           //
//                                                                    ...',,;;;;,''..   .,oxxdolllooodddoc;,...,:oxdc'           .;x0000KKOd:'':d0XNKd:l0XXO:.  .:dkOOO0XXKk:.                   .cxkl,           //
//                                                                                       .,:clllollcc::;,...   .:ddc.        ...',okOd::oOKKOkO0KKK0x:'ckXX0o,..cOXNXXKK0Okl.      ...           .cxxl'           //
//                                                                                          ........           .:dxl'.   ..,:lodddxko,. .;ok000Oxo:,.  .lOKXKOdokKNX0xl:,'..     'lxxo;.        .:xkd;.           //
//                                                                                                             .'cddoc:::codddolldxxc.    .';;;,..      .:x0XXXXXXNKx:. ..,,'.  .c0XXKx;      .,lkko;.            //
//                                                                                                               .,:looooolc;'...;oxo,.                  .':oxOO0Oko;. .:k0K0kdclkKXKOl'   ..;lxOxl,.             //
//                                                                                                                 ........      .:dxl'.         .          ...'''..   'xXNNNNNXXNXKxc,'';coxkOxo;.               //
//                                                                                                                                .:dxl,.    .,:clc:,.                 'dKXXKKKKXXXX0kkkOOOkxoc,.                 //
//                                                                                                                                 .;oxo:...'cdkkOOOko;.               .:kKXXKOkxxddxxxdol:,'.                    //
//                                                                                                                                  .'cdxo:,:ooc:;cdO0kl'  ..''..       .,coxO0Oxl;......                         //
//                                                                                                                                    .;oxxdl:,.. .'ck0kl'.:xO0xc.        ..,lk0xc'                               //
//                                                                                                                                     .':oxxo:..  .;d00d;;oOKXKx;.     ..;cdkOdc.                                //
//                                                                                                                                       .':odxol:;cx0NN0xodkO0Od:'.',:loxkkxo;'.                                 //
//                                                                                                                                         ..,codxOKNWNNNNNXXXXX0kkkOOOkxoc;..                                    //
//                                                                                                                                            ..,lOXNK0KNWWWWNX0xddolc;'..                                        //
//                                                                                                                                              .l0XOodO0000Okxl'....                                             //
//                                                                                                                                             .:kKk:,dOkkxxxxko,.                                                //
//                                                                                                                                            .,d0Oc. .,,,,,:x0x:.                                                //
//                                                                                                                                            .ck0o'        ;x0d;.                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SEC is ERC721Creator {
    constructor() ERC721Creator("Web3 Security Token", "SEC") {}
}