// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Aqueous
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                   .:dxkkkxxxxxxxxxxxxxdl;..                                   ..                       ,xxxxxxxxxxxxxxxxxxx    //
//                   .lxxxkkkkkkxxxxxxxxxol,.                                     .,.                     ;xxxxxxxxxxxxxxxxxxx    //
//                   'oxxxkkxxxkxxxkkkkkxol;.                                     .'.                    .lxxxxxxxxxxxxxxxxddd    //
//                   .oxxxxkxxxxxxxxxxkkxddl:;:clcc'   .                                                 ;xxxddxxxxxxxxxxxxxdd    //
//                   .ckxdodxxxxxxxkkkkOOOOkO0XNWNXkc'..                                                .lxxdloxxxxxxxxxxxxxxd    //
//                   .okxl',dxxxxxxxkOO0KKXXNNWWX0kxxc.                                           ..',:cloddoloxxxxxxxxxxddddd    //
//                   :xkxc..cxxxxxxkOO0KXXNWWWXK0OkOkxl'                                          .;oxxxddxddxxxxxxxxxxxxxxxdd    //
//                  .okkxl..:xkkkkOO0KKXXNWWNXKKKKK0Oxdc.              AQUEOUS                    .;dkkxxxxddddddddxxxddxddddd    //
//                 .:xkkd:. 'dOOO00KXXXNNNXKKXXXXXK0Okdc'                                         ,xOOOkxxxxxxxxxxxxxxxxxxxxxd    //
//                .;dkkxc.   cO0KKXNNNNWNKkk0KXXXXK0kdl;.                                         :k00OOkkxxxxxxxxxxxxxxxxxxxd    //
//                ;dkkxc.   .l0KXNNWWWWWWWNNNNXXXXX0kl,..                                         .c0KK0Okkxxxxxxxxdxxxxdddddd    //
//               .ckxd:.  .lk000KNNWWWWWWWMMMMWWWWWNKd:.                                     ... .'lxk0K00Okxxxxxxxxxxxxxxxxxd    //
//               'dd:.   .dKKXX0O0XXXNNXXXXNNNWWWMMWWXOx;.                                ..''.  .:ccldxxkkOkkkkxxxxxxxxxxxxxx    //
//               :d;.   .dKXNNWXdcdk00OO0KKXXXXXXXNNNNNXKx:.    .............'',,.        ..''...,;;,,,'',,:looxkkxxxxxxxxxxxx    //
//               ,l,.,:d0XNNWWXx;..':lcodxOKXKK00XNNXKXNWWWKxodk0XXXXXXXXXXXXXXXKOl'.        .....      .      .,cldxxxxdddddd    //
//                .lOKXXNNWWXx;........';;coxkO0KKXXXXXWWWWWXkxkOO00KKXNNWWMMWWWNWN0xd:......                    .:oddxddddxdd    //
//                .oXXNNWWKd;.  ..'.    ..'codk000KKXXNWWWNNXOoooooodddxkO0OkOOO000Oxo;....                      .;oxddddddddd    //
//                .dXNWWKd,.              .;ldxxddxkOKKKOddkOx:';;;;;,,,;;;,..'',,'..                            .;odxdddddddx    //
//                .kXWNk;.                  ':llcloxOKKOl':xkxl,''''............                                .lxxkxddddddxx    //
//                .xN0l'..            .,'     .';ldOKNN0dloOK0Oo;;;;'....                                    .,lx0KK0Okxddo:;:    //
//               .ckkoc,......        cx:       .,lx0KOxddddOkoc'...       watercolor artist                 .lkO0XNWNNX0OOxl;    //
//               ,dxxxoc;,,,.        .,'          .,cc::ccc;:;..            gone digital maven              .:xxlloxO0XWWNNXXX    //
//               :xxolllccl;.       ..                 ..                                              ..';lxO00d;....;xXNNNNN    //
//              .cc;cllllc;.                                                                         .clldxkO00Kx'     ;KWWN0x    //
//             .,;;:loool,.                               .....,;;;;'.....                          .lxdoddkOO00k,  .,cOWWW0ol    //
//             ',,cddolc,.                           .',:llodddONWNWXkkO0Okdlc:::;,..               cxxxxddxxxkkxl:oOKXNNNOllo    //
//            .:ldxl:,..                            ,looddddxxdxKWWWWKOKXXNXXKKKXXXK0Odc,..         :kkkkkkxdddxk00kdol::,....    //
//           .dOkxl,.                              ,loooooddddddxXWWWNXKNNNNNXXXXXNNNX0OOOxoc;..    .okkOOOkkkOKNWKl'...          //
//           ;00xl,.                              .clllloooddddookXNWWNK00KXXXXXXXXKK0kkOOkkkkkxo:.  .lkOOOOO0XNWWNk:,;.......    //
//           :O0xc.                               .lllllooooodoooxOKNNWXxoodxO0KK0OOOkkxkkkkkkkkkOkl,.;xKKKKXNNWWWWWXk,  .....    //
//          .cxOKx,     .;:;..                    .:ooooooddddxxdxkKNNWWXOxdooxOKOxxxxdodkO0OOOkkO0OxlckXNNNNNNXXWWMNk:.          //
//         .,oOKKOc.    c0KOd:..                   'ldddddxxxxxxxkKXNNNWN0Okdc::c:,;:;,:lxkOOOkkO0000OxxKNWWWNKKNWWNkcc,          //
//        ':cdkxxd;    .oXN0o;..                    ;ddddxxxkkkxdxxxdONXd;'.............',;::coxOO0KK0dl0WWNXKXNWWNkoodx:..'''    //
//        ..:olllo;.   .xNWN0dollllcll:'..          ,oddxxxxxOXKkolodxKNk,.           .........;clclccoOXXK00KNWNKkx0NNWN00XNX    //
//          ,llldd:.  .:0WWWKkO000OKWWNKkoc,..      .lddxO0O0XNXkoooddkXNk:.             ..',;;'..  .lKX0OO0KNWWXK0KNWWMMW0doc    //
//          .codddc,,cd0NWMNkxkOkx0NWNXkoooc;'.      .lkKWWNKOkdooooodx0NWOc,.          ..';ldxl'  .cO0000KXWWWX0kOXWNX0Od,       //
//          'loxko:cxO0XWMWKdododONWWNkc:lc:'.        ,0WWXOolooddddxxxkKWNXOc.        ....;oxxdl,'l0KXXNNWWWN0o:;cxxoc:::;,''    //
//          .:lol::x0O0NWWNOdddx0NWWNOl'.....         .ckkxdodddxxxxkkkkOXWWW0:         ...'cdxddx0NWWWWWWWXOo,...;:cccc::::::    //
//          .,lc;:ok00XWWWKxddx0NWWNko:.          .:do,.,oxxkkxkkkkkkkkkxONWWNx.       .....,oOKXNNNNWWWWXkl,.  .',',,;;::cccl    //
//      .,cc..:cccok0KNMMNOddxKNWWNklc,.          'll,.  :kOOOOOOOOkkkkkkk0NWW0:        . .;okXWWWWWWNNXOl;.     ........,;:cc    //
//     ..;lc..;oollk0XWMMXxdkKWWNKd:;'.                  .cO00000OOOkkkkkkkKNNN0xdl,.    .lKNNWWNWWN0xoc,..          . ..;clc:    //
//            :xd::d0NWWW0ddOXXKk;...                     'kK000OOOOOkkkkkOKXKOxxOXX0dc:cxXWNNWWXKKx:,'...            ..;lolll    //
//           .;ol;';d0XNXkdk0KK0l,'..                    .'x00OOOOOO00KK0xdoc,.  ;kXNNWWWNWWWWWN0d:;;;,'.         .....;coc...    //
//      .';cl;,cl:..':lkkdkKKXKxlll:..                .:dkkO0KKXXNNNNWWW0l'....'l0XXXWWWWWWWNXKK0o;;;;:,.   . ..... ..,::c;.      //
//      .,oxxl,coc,....,;d0KXKxllc;..               .ck0KXXNNWWMMWWWWWWNNK0kO0OkkkdookXWWWWXkdool,.. .'. ..        ..':lool:,.    //
//      .:dxxo:lddc'   .;dkxxoc:,.                .ck0XNWWMMMMWWWNXXKKKKK0kdl:,...,:cd0NWNX0dc,..                 .,:oxkkkkkxd    //
//     .;dxxxdloddo;.   ..... ..               'cxKNWWMMMMWWNNNXK0Okkxoc;'...';ldkKKkddkXNKOo.                  .codxkkxxxxxxx    //
//     .cdxxxdddxxdl.                        ;kNWWWWWWNNXKKKKKKKK0Oxc:;,:llloOKKOdllcccxKN0:.                  .lxo:coxxxxxkkx    //
//     .,:loodxxkxxd:....                  .dNMWNXK0OOkkkxxkOO0XXXKKXNNNK0Odlc;'..cx0K0OKKc                   .cdxxooxxxxxxxxx    //
//    ...',;:ldxkkxxxdoool'               .kXK0OkkxxxkxxxddddxO0XNNNKkxo:,...,:cdKXKkl:cko.       ..'''',,,;;codxxxxxxxxkxxxxx    //
//      ..,:lolodxdol:;;::.               ;kkxxkkxkOkkkkkkkxxdoco0K0x;.,;;:dOOkkxl;,''dkl'..  .;,,clooooddddxxxxxxxxxxxxxxddxx    //
//     ..';lddocccc:,....                .dOOkO0OkxxkOOkxkkOOxoloxxkOOO00d:;,..... .,xW0; .......,coddddddxxxxxxxxxxxxxxxxdoll    //
//    ;coodxkxxxxdddoc:,'''''.           :KXKKXNXX0kkkOkkkOOkxooodxk0KKKKkoodddddkkk0NXo.........;lodxxxxxxxxxxxxdlcllloddo:'.    //
//    ,:lodxkxxkkkkxo:.'oxxxxdc.         lKK0KKK0kdxkkOOkkkxxxdo:,;l0XXXNNNXK00OOKXNKxc'...... ..',;;;;;;:::::;;;,.....';clccc    //
//    .,:odxxkxkkkkko' .okkkxxxo,        :kxdxxxo:;cdxkkxdoc;;,'....cKNNWNKOO000K0Ox;........            .','...',,,,;cldxxxxx    //
//    :ldxxxkkkkxxxko. ;xkkkkkkxd:.       .';lxdlc:',:cc:;'...      .oNWWX0O0KKXNXXk;..                 .'coddddxkkkkxxxxxxxxx    //
//    oxxkkkxxxxxxxxl..lxxkkkkkxxdl;.        ......    ...           ;KNKOO00O0XXK0Oc..            ...,coxxxxxxxxkkkxxxxxxxxxx    //
//    kkkkkkxxxxxxxxxooxxxxxkkkkxxxxdl,.......                       .xX00000KXX0OOOc.         ..;ldddxkxxxxxxxxxxxxxxxxxxxxxx    //
//    xkkkkkkxxxxxxxxxxxxxxkkkkxxxxxxxxxxxxkOko;.                     ;OK0OO0XX0OOO0l       .'coxxkxkxxxxxddxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxkkxxxxxxxxxkkxxddxxxkkOkkO000x;                     .xKOO0KX0Okk00:      .,lxxxxdxxxxxdxxddxxxxxxxxxxxxxxxxx    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AQUE is ERC721Creator {
    constructor() ERC721Creator("Aqueous", "AQUE") {}
}