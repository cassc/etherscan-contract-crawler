// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: VLIZZY
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                     .;'   ..       ..''..'c;.                 ...  .                                                           //
//        ..         .;c,.           ..'....,;.                  ..                             ..                                //
//                   ...                                            .....                    ....                                 //
//       ...    .              .                     .           ...,,'..',..               ...  .              ..                //
//     ..''...:xl.                                               ......':lc.                .   ...           ..                  //
//    ........,;.           .          .''..',,'.',;'.           ...',;::cll;..             ..                ..                  //
//                                  .;lxO0OkO0OOkxkkkdc'       .;llooll,...;odo;.          ...        ...     ..                  //
//     ..        .   ..        ...'ckKXXXNXXXK000kkOO0Oxc'.  .:xOOko::l:.   .;dkxc'.       .  ... ..   ..     ..                  //
//     .             ..      .',;o0KXXXKKKKK0OO0OkkO00Okkkd:cxOOd:',:dkl.  ...:xkkd'         .....         ..               .     //
//               .          ..'lOXXXKKKK000OOxxkkkOO0KKOkOkkkOd;.';lxoc;...,coxkd:.       ...  ..      ....'.             ...     //
//              ...          'xKKXXXNNNXK0OOxdxkkOO0KKKKOkkOO0x;:xOkc.  .;dkOxl,.   ..  ....   ..      .''...  ..       ...       //
//                         .;ONNNWWWWWWNXK0OxdO0OOO0KKKK0O0KKXK0kkkxc,...';;,.      ...  .            ...  .  ...     ...  ...    //
//        ..       ..    .,xXWWWMMMMMWWNNKOxdxO0OO000KKKKKKXNNNXK0Okddd:....             .     ....           ...  ....   .. .    //
//        .            .,dXMMMMMMMMMMWWWNXxodk000000KXKKXXXNNNNNXKKKOkkkl:lc:,..     .    .   ..... ....  .. ..... . .  ......    //
//      .            .;dXMMMMMMMMMMMMWWWWKdoxO00000KKXKK00XNNNNNNXXXXK00OookOkdoc:;;;,'''''',,:::;:::ccc:::;,,'........',,,''.    //
//                ..lONMMMMMMMMMMMMMWWMWXxodO0000KKKKXKKk;cKNNNNNNNNNXXXKklokkkkkkkkkkxxxxdxxxxxxxddddddddddddoolloooooddxddol    //
//                ;OWMMMMMMMMMMMMMWNWMMXkodOKKKKKKKKKXKKd..oNNNNNNNNNNXXK0ocxkkkkkkxxkkkkkkkkkxxkxxxxxxddddddddddddddddddddxxx    //
//               ,0MMMMMMMMMMWMMWNXXWWX0kkO0KKK00KKKKKKO:. 'dKNWWNNNNNXX0xlokkkkkkkkkxxxkOOkkkkkxxxxxxxxxxxxdddddddxxxdddddoll    //
//              .kMMMMMMMMMWXKNNXKKKXXKKKK0KKK00KXKKK0d,....,ONNNNNNNNXXOc:xOkkkkkkkkkkkkkkxxxxxxxxxxxxxxxxddddddddddxdoo:,...    //
//              .OMMMMMMMMMNxo0XKKKXKKKKK00XX000K00Kk:.  ..;ONNNNNXNNNXXKd:okkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxxddddddoc:,''.....    //
//              .xMMMMMMMMW0ll0XKKXXKKKK0OKXK00K0O0x,   ..,ONNNNNNNNNXXXKxcokkkkkkkkkkkkkkkkkkxxxxxxxxxdddddddddo:,'..........    //
//              .oWMMMMMMWXdcdKXXXXXKKK0kKXK00000Ol.     .xNNNNNNNNNNXXXKxcokOkkkkkkkkkkkkkkxxxxxxxxxxxxxxdddddc.  ...........    //
//              .xWMMMMMMNOllOXXXXX00K0k0K00000Kx,.  .. .lXNNNNNNNNNNXXXKxclxkkkkkkkkkkkkkkkxxxxxxkxxxdddddddl,.  .....  ..  .    //
//    .        .dNWWMMWWNXkxOKXXXX00K0O0K0K00KKo.      .:KNNNNNNNNNNNXXXKxclxkkkkkkkkkkxkkkkxxxxxxxxxxxdddddc.............        //
//             .:lxXWNKKK00KXXXXK00K0OKK0K00KO:.       ,0WNNNNNNNNNNNXXXKxclxkkkkkkkkkkxxxxxxxxxxxxxxxxxxddc. ......  .           //
//               .dXXKOO0KXXXXXKKXK00000KK0Oo'        'kNNNNNNNNNNNNXXXXKxclxkkkkkkkkkkxxxxxxxxxxxxxxxdoc:;....      ..  .   .    //
//               .oXKOOKXXXXKKXXXXK000KKOxl'         .dNNNNNNNNNNNNNXXXX0dcldkkkkkkkkxloxxxxxxxxxxdol:,....                 ..    //
//               .kKOOKXXKKKXNNXX0O0K0x:..     ..   .lXNNNNNNNNNNNNNXXXX0dclxkkkkkkxo;..cdxdddddoc,...  .             .           //
//               :0OkKXXK0KXNXXX0kxdc'.        .....:0NNNNNNNNNNNNNNXXXXOoclxxdlc:;,.   .',,'''...   .                 ..... .    //
//              'xOx0XX00XNNXXXx,...           .. .'xXNNNNNNNNNNNNNNNXXXOl',,'...                                       ......    //
//     .       .oOdxKX0KXNNXKOl.                  'd0XNNNNNNNNNNNNNNNXXKO:.                 .                           ......    //
//            .:xc;kXKKXXKko;.                  .'d0XNNNXNNNNNNNNNNNNXXKk,                 ......               .       ..        //
//            ,l'.cKK0K0o,.                    .;kKXXNNXNNNNNNNNNNNNNXXKd.         .       ..  .                                  //
//      ...   .. 'kX0kl'                ...   .cOXXNNNXNNNNNNNNNNNNNNNXKl.                                               .....    //
//      ...     .oKk:.                      .,dKXXXNNXNNNNNNNNNNNNNNNNX0:                    .                    ...     ....    //
//              ,kd'                       .lOXXXXXNXNNNNNNNNNNNXNNXXXXO;                     ...         .      .............    //
//              ...          ..          .,xKXXXXXXXXNNNNNNXXXXXXXXXXXKk,                                 ...... .. ..........    //
//                         'ldl:,.      .cOXXXXXXXXXXNNNXXXXXXXNNXXXXXKx.                                     ....  ..........    //
//                        'd00Okxoc,....o0XXXXXXXXXXXXXKKKXXXXXNXXXXXXKx.  .                                  ..    ..........    //
//    cl:;,'.;cc::,',,,,;:lxxxdddoool:cxKXXXXXXXXXXXKKKKKXXXXXXXXXXXXKKd. .,,'......           .'cc;.                ......  .    //
//    Okkxdddxkxddoc:ccllloddddxxdoooxOKKKKXXXXKKKKKKKKXXXXXXXXXXXXXXKKd. .:oll:;,,;,,,'....  .:k00Od:.              ....... .    //
//    ddddddooooooddo:,',:lllllodoook0KKKKKKKKKK00KKKKXXXXXXXXXXXXXXXK0x' .,cllllcccccllc;'...'x0000Oko;.            ......  .    //
//    lllcc:cclllxO0Od,..;llllccccok000KK00000000KKKKKKKXXXXXXXXXKKKKK0x,  .cooc:,'.',;:cc:;;:dO0K000Oxdl;..          ......      //
//    odxxdollodkKXXK0xllloddddddxO000000O00000000KKKKKKKKXXXXKKKKKKK00k;  .ldxkkxoc;,:cclldkO00000000xdool:'.          ...       //
//    ollodxkOO00KKKK0OkxdddxxxxxkOOOOOOOOOOOOO00000000KKKKKKKKKKKKKK0Ok:. 'clllodxxxddoddxkkO00000OOOxdoooll:,..   ........      //
//    c;'';coddxxddxxxxxdddxxxxxxxxxkkkkkkkkkkkkkOOOOO00000KKKKKKKKK00Okl. .c::ccccccccclloodddddddxxddoooolllcc:,'...',,;:;,'    //
//    0OxolloodxxxolllooodddxddoddddxxxddddddddddxxkkkkOOO000KKKKKK000Oko'.:do::loolc:::c::::c::::clllc::::;;;:cccc:;,,,'',;:l    //
//    kkkxxxdddddoolc::lddooooddxxxxxxxxxxxxxdddxxxxxdxxkkOO00000000OOkxd;'cdxd:;ldddddddoc:;;;'...:xkd:.     .,:::c::::;,''''    //
//    oollcc:coxxxxxxxxxxdoolcloddooodxkkxoc,..':odddddxkkOOOOOOOOOOOkkxdlcodddl;,;coodxkkkxdlc:,':OKKK0x:.     ':cclodxddoc:;    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract VZ is ERC721Creator {
    constructor() ERC721Creator("VLIZZY", "VZ") {}
}