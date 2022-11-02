// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: VLIZZY
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//               .                                                                              ...                               //
//                                                                                              ...                               //
//        ..                                                                                                                      //
//        .                                         ..                                               ...                          //
//     ..       .. ...                              ..        ...         ..                  ..   ..''.  .     ..                //
//                 ..                           .''.          ..       ....    ..                 .''..   ..                      //
//                           ..          .     .,;.                   ....    ...                 ...                     .       //
//                     .;'   ..       ..''..'c;.                 ...  .                                                           //
//        ..         .;c,.           ..'....;:.                  ..                             ..                                //
//                   ...        .                                   .....                    ....                                 //
//       ...    .              .                     .           ...,;'..',..               ...                  .                //
//     ..''...:xl.                                               ......':lc.                .  ....           ..                  //
//    ........,;.           .          .''..',,'.',;'.           ...',;::col;..             ..                ..                  //
//                                  .;lxO0OkO00OkxkOkdc.       .;lloool,...;oxo;.          ...        .'.     ..                  //
//     ..        .   ..        ...'ckKXXNXXXKK000kkOO00xc'.  .:xOOko:;l:.   .;dkxc'.       ...... ...  .      ..                  //
//    ..             ..     ..',;o0KXXXXKKKK0OO00kkO00Okkkd:cxOOd:'':dko.  ...:xkkd'         .....         ..               .     //
//               .          ..'lOXXXKKKK000OOxxkOkO0KKKOkOkkkOd;.':lxol;...,coxkd:.      ....  ..      ...''.              ..     //
//              ...          'kKKXXXNNNXK0OOxdxkkOO0KKKKOkkO00x;:xOOc.  .;dkOxl,.   ..  ....   ..      .''..   ..       ...       //
//                         .;ONNWWWWWWWNXK0OxdO0OO000KKK0O0KKXK0kkkxc,. .';;,.      ...  .             ... .  ...     ...   ..    //
//        ..       ..    .,xXWWMMMMMMMWNNKOxdxO0OO000KKKKXKXNNNXK0Okddd:....             .     ....           ...  ....   .. .    //
//        .            .,dXMMMMMMMMMMWWWNXxodk000000KXKKXXXNNNNNXKKKOkkkl:ll:,..     .    .   ..... ....   . ....... .  ......    //
//     ..            .;dXWMMMMMMMMMMMWWWWKdlxO00000KKXKK00XNNNNNNXXXXK00OookOkdoc:;;;,'''''',,:::::::ccc:::;,,'........',,,''.    //
//                ..lONMMMMMMMMMMMMMWWMWXxodO0000KK0KXKKk;cKNNNNNNNNNXXXKklokkkkkkkkkkxxxxxxxxxxxxxxddddddddddoolloooooddxddoo    //
//                ;OWMMMMMMMMMMMMMWNWMMXkodOKKKKKKKKKXKKd..oNNNNNNNNNXXXK0ocxkkkkkkxxkkkkkkkkkxxkkxxxxxdddddddddddddddddddxxxx    //
//               ,OWMMMMMMMMMWMMWNXXWWXOkkO0KKK0KKKKKKKO:. 'dKNWWNNNNNXX0xlokkkkkkkkkxxxkOOOkkkkxxxxxxxxxxxxddddddddxxdddddoll    //
//              .kMMMMMMMMMWXKNNXKKKXXK0KK0KXK00KXKKK0x,... ,ONNNNNNNNXXOc:xOkkkkkkkkkkkkkkxxxxxxxxxxxxxxxxddddddddddxdoo:,...    //
//              .OMMMMMMMMMNxo0XKKKXKKKKK00XX000K00Kk:.  ..,ONNNNNXNNNXXKd:oOkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxdddddddol:,''.....    //
//              .xMMMMMMMMW0ll0XKXXXXKKK0OKXK00K0OKx'.  ..,ONNNNNNNNNXXXKxcokOkkkkkkkkkkkkkkkkxxxxxxxxxdddddddddo:,...........    //
//               oWMMMMMMWXdcdKXXXXXKKK0kKXK00000Ol.     .xNNNNNNNNNNXXXKxcokOkkkkkkkkkkkkkkxxxxxxxxxxxxxxdddddc.  ...........    //
//              .xWMMMMMMNOllOXXXXX00K0k0K00000Kx,. . . .lNNNNNNNNNNNXXXKxclxkkkkkkkkkkkkkkkxxxxxxxxxxdddxdddl,.  ....   ..  .    //
//    .        .dNNWMWWWNXkdOKXXXX00K0k0K0000KKo.      .:KWNNNNNNNNNNXXXKxclxkkkkkkkkkkxkkkxxxxxxxxxxxxdddddc..............       //
//             .:lxXWNKKK00KXXXXK00K0O0K0K00KO:.       ,0WNNNNNNNNNNNXXXKxclxkkkkkkkkkkxxxxxxxxxxxxxxxxxdddc. ......  ..          //
//               .dXXKOO0KXXXXXKKXK000KKKK0Oo'        'kNNNNNNNNNNNNXXXXKxclxkkkkkkkkkkxxxxxxxxxxxxxxxdoc:;....      ..  .   .    //
//               .dXKOOKXXXKKKXNXXK00KKKOxl.         .dNNNNNNNNNNNNNXXXX0dcldkkkkkkkkxloxxxxxxxxxxddl:,....    .            ..    //
//             . .kKkOKXXKKKXNNXXKO0K0x:..     ..   .oXNNNNNNNNNNNNNXXXX0dcldkkkkkkxo;..cdxdddddoc;...  ..                  .     //
//               c0OkKXXK0KXNXXX0kkdc'.        .....;0NNNNNNNNNNNNNNNXXXOoclxxdlc:;,.   .',,'''...   .                 ..... .    //
//              'xOx0XXK0KNNXXXx,...           .. .'xXNNNNNNNNNNNNNNNXXXOl',,'...                                       ......    //
//    ..       .oOdxKXKKXNNXXOl.                  'd0XNNNNNNNNNNNNNNXXXXO;.                 .  .                        ......    //
//             :kc;kXKKXXKko;.                  .'d0XNNNNNNNNNNNNNNNXXXXk,                 ......               .        .        //
//            ;l'.cKK0K0o,.             .      .;kKXXNNXNNNNNNNNNNNNNXXKd.         .       ..                                     //
//      ...   .. 'kX0Ol'                ...   .cOXXXNNXXNNNNNNNNNNNNNNXKl.                                               .....    //
//      ...     .oXk:.                      .,dKXXNNNNNNNNNNNNNNNNNNNNX0:                    .                    ..      ....    //
//              ,kd.                       .l0XXXXNNXNNNNNNNNNNXNNNXXXXO;                     ...         .      .............    //
//              ...          ..          .,xKXXXXXXXXNNNNNNNXXXNNXXXXXKk,                                 ...... .  ..........    //
//                         'ldl:,.      .cOXXXXXXXXXXNNNXXXXXXXXNXXXXXKx.                                     ....  ..........    //
//                        'd00Okxdc,....o0XXXXXXXXXXNXXKKKXXXXXXXXXXXXKx.  .                                  ..    ..........    //
//    cl:;,'.;cc::,',,,,;;lxxxdddddolccxKXXXXXXXXXXXXKKKKXXXXXXXXXXXXKKd. .,,'......           .'cc;.                ......  .    //
//    OOkxdddxkxddoc:clllooodddxxdooox0KKKKXXXXKKKKKKKKXXXXXXXXXXXXXXKKd. .:oll:;,,;,,,'....  .:k00Ox:.              ....... .    //
//    ddddddooooooodo:,',:llllloddook0KKKKKKKKKK000KKKXXXXXXXXXXXXXXXKKx'  ,cllllcccccllc;'...'x0000Oko;.             .....  .    //
//    lllcc:cclclxO0Od,..;llllccccok000KKK0000000KKKKKKKKXXXXXXXXKKKKK0x,  .cooc:,'.',;:cc:;;:dO0K0K0Oxdl;..          ......      //
//    odxxdollodkKKKK0xolloddddddxO00000OO0000000KKKKKKKKKXXXXXKKKKKK00k;  .ldxkkxoc;,:ccllokO00000000xdool:'.          ...       //
//    ollodxkOO00KKKK0OkxxddxxxxxkOOOOOOOOOOOOO00000000KKKKKKKKKKKKKK0Ok:. .llllodxxxddodxxkkO00000O0Oxdoooll:,..    .........    //
//    c;'';coddxxddxxxxxddxxxxxxxxxxkkkkkkkkkkkkkOOOOOO000KKKKKKKKKK00Okl. .c:;:cccccccclloodddddddxxddoooolllcc:,'...',,;::,'    //
//    0OxolloooxkxollloooddxxddodddddxxxdodddddddxxkkkkOOO000KKKKKK000Oko'.;do::loolc:::::::::::::clllc::::;;;:cccc:;,,,'',;:l    //
//    kkkxxxdddddoolc::lddooooddxxxxxxxxxxxxxdddxxxxddxxkOOO00000000OOkxd;'cdxd:;ldddddddoc:;;;'. .cxkd:.     .,::::::::;,''''    //
//    oollcc:coxxxxxkxxxxdoolcloddooodxkkxoc,..':ddddddxkkOOOOOOOOOOOkkxdlcodddl;,;coodxkkkxdoc:,.:OKKK0x:.     ':ccloxxddoc:;    //
//    oolllc;',cooddxkkxxdllooccoxkxdk0XXKOd:..  .:loooodxkkOOOOOOOkkxxdddxxkkOOkdlcoooooddxxkkdodOKXXXKK0x:.    .clodxkkOOkxx    //
//    xxxxxkkdlldxdddodxkxxooolllodkOKXNNNXXKko;.  .cooodddxxdddddddddoooooooooollllloollloooddxO0KKXXXKKK0kd;.   .:lllloddxkk    //
//    OOkxddddlcoxkdc;',:loollcllcokKXNNNNNXXXKOd:'..,codxxxxddddddddddolllllloooollodxxkxxkkOO0KKKXXXKKKK0OOkl,.  .;lllcclodx    //
//    0kOOOxdol:cx00Oxdc,cddoolccld0XXNNNNNXXXX00kdc'..;oxxxxxxddddxxkOOkxdoodxkOOkxxxxkkkxkkO00KKKKKKKKK0OO0Odl:.  .:lollllod    //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract VZ is ERC1155Creator {
    constructor() ERC1155Creator() {}
}