// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Colorful Planets
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    OOOOOOOOxc.     ...........................'............................  .......  .                                                        .;dkxxOOOO    //
//    OOOOOOOkd,      ...........................'.............................  ... ... ..                                                        .ckkxxOOO    //
//    OOOOOOOxc.      .........................................................    .  .   .                                                        .,dOkdxOO    //
//    OOOOOOko'       ............................................. ...........                                                                     .:xOxdkO    //
//    OOOOOOx:.       ...........................................    .  ......                                                                      .,oOOxxk    //
//    OOOOOko,        .....  .. .................................        ....                                                                        .ckOkxx    //
//    OOOOOxc.          ..   .  .....................   ........                                                                                     .,dOOxd    //
//    OOOOkd,.                   ........ .... .....     .....                                                                                       ..lkOkx    //
//    OOOOkl.                    .... ....  .   .....    ....     .                                                                                   .:xOOk    //
//    OOOOx:.                    ...  ..'.       ....     ...     ..    ..                                                                            .,okOk    //
//    OOOko,.                     ...  .;.       ...       ..     ..    .'.                                                                           ..cxOO    //
//    OOOkl.                           .:;.       ....            .,.    ',.                                                                           .:dOO    //
//    OOOx:.                 ..        .:o,       .....            ';.   .;,.                                                                          .,okO    //
//    OOkd;.                 ..        .;xc.      ......           .:,.  .,c;.                                                                         ..cxO    //
//    OOkl,.                 ...       .,xx'       ......   ...    .;c'.. .:o:.                                                                        ..:dO    //
//    OOxc'                  .'.        .oOc..     .....'. .........'l:....,okl..      ..                                                              ..,ok    //
//    Okx:.                   ''        .:Ox'....  .....,'...........:c,.'.'cx0d'..     ....                                                           ..'lk    //
//    Okd;.                   .,.   .....'d0l'..........,;...........;c;.,;.;okKOd:...  ......                                                         ...:x    //
//    Oko;.                   .;,. .......c0k:,'........';'..........'c:'':c':dx0NKo.. ........                                                         ..;d    //
//    Oko,.                  ..'c:........,kXd:;'''..'''.,;,''''....'':l;.,oo;cxxxO0d,. .,...'..                                                       ...,o    //
//    Okl'                  ....cxo'....'.'oX0oc,,;,'',,';::,,,;;',,',;ll'':odclk0OOOx:...::,''..                      ..                              ...,l    //
//    Okl. ..               .',',ldo;,,''',c0N0dl;;::;;:;;loc;;cl:;l:,;cxo,;cokoloxOO00xc''cxdcc:,.                    ..                              ..',c    //
//    Okl....               ..''.'',,.';;,,:xXN0xl:cll:clclxkocoxdclxl:cx0dcdxxkoc::::::cc,.;dolool;.                   ..                              .,,:    //
//    Oxc.':'               ...        ..';:o0NNKkxooddloolkK0xdkOkox0kdkXX0K0kl;,..      .   ..,;:;'.                  ..                              .;::    //
//    Ox:':l,.                   .,cl:''...':xXWWNKK00KOdddkXXKOOKX0kKNNNNNKkollc:,',,'....                             ...                             .;c:    //
//    kx:,ld;.                 .;kXWXd:ll,...;xXWMWWWWWWXKKXNWWWWWWWWWWWWN0kkOKXkcclxkd;.'''...':,......                ...                             .;cc    //
//    kd;;od;.                 .oNMMXd::;,',,';kNMMMMMMMMMMMMMMMMMMMMMMMWXKXWWMWkc:cllc,..,;;;';xkl:ldc'                 .                              .;cl    //
//    ko;:dx:.                .,lKWMWkc:cc;,,::lKWMMMMMMMMMMMMMMMMMMMMMMWWWMMMMM0dlcool;..;cll:cOKxd00kc.                                               .:cl    //
//    ko;:xk:.                ;odOXWMNkllol;;coo0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNOddddoccoddolkX0k0XX0l.                                               .cll    //
//    kl;ckkc.                ,x00O0NWN0doddddxkXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKOxxxxxxxxk0XXKKKXN0l.                                               ,llo    //
//    kl;lkOo..               .d00OkOKXNX0OO00KNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWXK00OOO0KKKKXXXNN0c.                                              .;olo    //
//    kl:lkOd'.               .lOKKKKKKKKXXXXNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWNNXNNXK0KK00XXXNNNNO;                                               .colo    //
//    ko:lkOx;..               ;kKNNNNNXXXNNNWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWNNNXXNNNNNWWWWWNk,                                              .,oold    //
//    ko:lkOx:..               .dKNWWWWWWWWWWWWWMMMMMWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWNx.                                              .cdlod    //
//    kdclxOkl'.               .c0NWWWWWWWWWWWWMMMMMWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMWWWWWWWWWWXo...                                        .  .;ooldx    //
//    kxlcxkko,..               ,kNWWWWWWWWWWWMMMMMMWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKc...                                       ..  .colodx    //
//    kkocokkd;'.               .oXWWWWWWWWWMMMMMMMMWWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0:''.                                      .'. .;ooodxx    //
//    kkxllxkxc,'.               ;0WWWWWMMMMMMMMMMMMWWWWWWNNNWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNk,;,                                      .',. 'ldddddd    //
//    kkkdldkkl:,.               .lXWMMMMMMMMMMMMMMMWWWWNNNNNNNWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXo,:'                                      .;'..cddddddd    //
//    kkkxookkdc,.                .dNMMMMMMMMMMMMMMMMWNNNNNXKKXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0:,:.                                     .;;..:oddddddd    //
//    kkkxdoxkxl;.                 .dNMMMMMMMMMMMMMMMMWNNNNNNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx';;.                                    .;:'.;odddddddd    //
//    kkkkxodxko;..                 .cKWMMMMMMMMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl.,.                                    .;l;.;oddddddddd    //
//    kkkkxdodkd:..                   ,xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO,...                                   .,oc,:odddddddddd    //
//    kkkkkxooxxc..       ..           .:ONMMMMMMMMMMNKXNNNWWWWWWWWWWWWWWWWNX0KWMMMMMMMMMMMMMMMMMMXo.                             ..      .'lo:coddddddddddd    //
//    kkkkkkxodxl'.       ',.            .:ONMMMMMMMMNKOkxxxkOOOOOOkkkkkkkOOkOKWMMMMMMMMMMMMMMMMMNx'                             ..    ....coccodddddddddddd    //
//    kkkkxkxdodo;..      'c;.             .:kNMMMMMMMMWX0kxdddddddxxxkkOKXNWWMMMMMMMMMMMMMMMMMMWO,                            ....   ...':olodddddddddddddd    //
//    xxkkkkxxxol:,...  . .:o:.              .:kXWMMMMMMMWNXKKKKKKKKKXXXNWWWMMMMMMMMMMMMMMMMMMWNk,                            .,'.....';:coodddddddddddddddd    //
//    xxxxxxxxxxdc;,........co:.               .,dKWMMMMMMMWWNNNNXXNNNWWWMMMMMMMMMMMMMMMMMMWN0d;.                            .;,...',:lloddddddddddddddddddd    //
//    xxxxxxxxxxxoc;....';'.,odc..                'oKWMMMMMMMMWWWWWWWMMMMMMMMMMMMMMMMMMMWN0d:.              .               ';'.';cloooodddddddddddddddddddd    //
//    xxxxxxxxxxxxlc;...';c;';dxo:,.                .lONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOo:...              ..             .,;;;cooddddddddddddodooddddoooooo    //
//    xxxxxxxxxxxxol:'..,:odc,:dxdl:'.                .:xXWMMMMMMMMMMMMMMMMMMMMMWNXOdc,.....             ...             .;loooddddddddddddooooooooooooooooo    //
//    xxxxxxxxxxxxdlc:'',codxoccoxxdc;'.                 'oONMMMMMMMMMMMMMMMWX0xc:;'.......            .....          ...:looddddddoddddoodooooooooooooooooo    //
//    xxxxxxxxxxxxxoll:,,:odxxdolodxdo:,..                ..;d0XWWWWWWWNX0xo:'............     ...    .....          ...',;cloooooooooooddoooooooooooooooooo    //
//    xxxxxxxxxxxxxdool::codxxxxddoodddo:'.......        ..'. .';:ccc:;'..     ........... .......  ..'''.      .   ..',,,'',:lolooooooooooooooooooooooooooo    //
//    xxxxxxxxxxxxxxdddooodddxxxxxdddddddoc,...':;.   .....;c;.                ................,'..';;;,.. ........',;,,,,,,,',coooooooooooooooooooooooooooo    //
//    xxxxxxxxddxxxxxdxddddddddxxxxdddddddddlc;;cllc,....,:codoc;'.     ..     .'''''.....',',:;..:llc:,...'..'.';ccccccc::::;,;odooolooooooollllooooooooooo    //
//    dddddddddddxxxxdddddddddddddddddddddddddddoooddocc:ccodddddoo:'...;c:,.  .',,,'',,;;::cl:',ldddo:''::,;cclooooooooooooolccoxxddoloddoooollllllllloooll    //
//    dddddddddddddddddddddddddddddddddddddddddddddddddddooddddddddollccoodol:'';::::::cclokkl;cxkOOOxlldocdO0000Okkkkxxxxxxxdodxkkkxdloddddoooollccccclllll    //
//    dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddooc::cclllloxO0xldOKXNNXK00kOKNWWMWWWNNXKK0OOOkkxxkOOOkxdoodddddoooolllcccc:ccl    //
//    ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddolclloodxkOKX0kOXNWWMWWNNXNWMMMMMMMMMMMMWWNNXKOkOOOOOOkdoodddddddooollllcc:::c    //
//    ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddolloodk00KNWNKKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKKXK00OOkddxdxxxxdddoooolllccc::    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PLANETS is ERC721Creator {
    constructor() ERC721Creator("Colorful Planets", "PLANETS") {}
}