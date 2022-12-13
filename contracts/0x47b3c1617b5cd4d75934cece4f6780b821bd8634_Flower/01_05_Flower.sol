// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Black & White Flora
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                          .'.                                                               //
//                                      .,coodo;.     .'..,'.                                                 //
//                                     'xOOxolooc;;:ldkkxkOOo,.                                               //
//                          .'...      .okkxdoddxxxdkOOOOxxkkxlc:'                                            //
//                         :kkkxdoc,.. 'd0XKkddxxdddkOkkxddxkxodxo:.        ..,,,'.                           //
//                        .okkkOOOOkdclx0XX0kxdxdddxkkxddddxxxdxdoo:.....,:loddodx;                           //
//                        .lxxkOOOOOkOO00K0Oxxdddddxdddoodxxxxxdoool;,:dkOkxddooxx,                           //
//                        .cxxkkkkkkkO000OOxxxdddddddoooddxxxxddool:coxkkxdooodxxdc'.                         //
//                         ,dxxkkkxxk0000Okxxdddxddoooooddxxddoooollodxxddddddxxxxxxo:,.                      //
//                          ;xxxxkkkkOOOOkxxddddddooooooddddodoooooodddddxxxkO0KKK0kxxdd,                     //
//                       ..,lxxxxxxkkOOOOkxxdddddooooooooddooollooodddxxxkO0KKKKK0Okkxdd:                     //
//               .';;::clokOkxxxxxxxxxkkkkxdddooolllloooooooolcloodddxxxxkOO00000OOkxddo'                     //
//              .okkkxxdxxOOkxxxxxxxxkkkkdoooolll:'',,,;;;;;;;;coodddddxxxkOOOOOOkkxxdl'                      //
//            ;dkOOkkkxxxxkxxxxkkkxxxxddoolc:;,''.          ...':cloddxkxxxkkkkkxxxxdc...',,,''..             //
//           'k0OOkkOOkxxxdddxxxxxdddoooll;.                   ...;ldxkxkkkkkxkxxxdo;.,;;clllllll;.           //
//            ':oxxxxxxddddddddoooooooll:,.           ...   .  .. .,ldxkkkkkkkkkxxo:;:cc::llooodo;.           //
//               .;odxxddddoooooooooll:'.                  ..  ..  ..:oxxxkkkxdoollllccccclooddo,             //
//               .'cdddxxdoolooooollc:.                         .. ...;ldxxkOOxxdddxxxxxdddodo:.              //
//              ,oxxddddddoolllllllc:'.                           .   .,:ldxkO00Okxxddddkkkdo;                //
//            .:kOkxxddddddooooolllc:.               .     ..          ..;ldxkkkxxxdooodxxxddo;.              //
//            'xOkkxddddddoooooooooc'..            ....       .         .;odkkOOOkxdoodxxddddol,              //
//             .:dxxddddddoooooooolc,.            ..         ...        .'cdkO0000Okkxxxdddddl;.              //
//            ':ldxxddddddoooooloooc.                       ....        .:oxOO0000OOOkxxdol:'.                //
//           ;kOOkkxxxxdooooolloodo:.                       ....        'cxkO00000OOkxdoolc,.                 //
//          .lOOOkkkkkxxxddoooooooc:,.   ..      ... ...........  ..  ..:ldxkOOOOOOOOOkkxoolc;.               //
//          .o0Okkkkkkkkxxdddooolc:::'.              ........ ..      .,ldxkkkOOOOOOOkOOkxdoll:;.             //
//           .;lddxxxxxddooolccc::::c:,..                ..         ...cdkOOOOOOOOOOOOOOkxolc;,;;;'           //
//              .cxxdooollol::::::cccccc,..                      ...':cdxkOOkkkOOOkkxxxxdolc'    ..           //
//             .:odooooolodl:::::cclloollc;..                 ...':cldxkOOOOOkxkkOkkkxdo:,'.                  //
//             .,cooool;'cxl:::::clooooodddl,'..'.... ..... .';;;:ldxkOO0OOOOOxxxkkxxxxdl:,.                  //
//                .,,'. .cxlcc:clloooodddxxollllllc:,';cllc;;cloooodxkOO000OOOkxddxxxdddddol'                 //
//                       cdolcclolloddddxxxdooooddxxxdooodxkxdddddddxkOOOOOOkkkxd:,coddddol:.                 //
//                       'oxolllllodddxxxxxooooodxkkkkOkkxxkOkxddddddxxkkkkkOOkxdl' .':cl:'.                  //
//                        :dlclooodddxxxkkdllooodxkOOOOOOkxxkOkddddddddxxkOO00Okdol'                          //
//                       .:ccloodddxxxxkxdlclooodxkkOOOOOOkxxkkkddxxolodkOOO0OOOxolc,.                        //
//                       .:clloddxxxxxxdlc:clcloddkOOOOOOOxddkOkdcldo::oddxxkkxxxdl::'                        //
//                        .':oodddddollc::cc;.,oddxkO0OOkkdodxkOxc:ll. .,:clllloool:,.                        //
//                          ;oooooolc::::c:'  .:ddxxkOOkxdoodxkkxo::c;.   ....''..'..                         //
//                          ..,lollc:::c:,.    .cdxxxkkdolloddxxxo:;::'                                       //
//                             ..';;:;,..       .cddxkxl:::loddddoc:::'                                       //
//                                               .ldxxo:;;:::codol::::;.                                      //
//                                                .cdoc;;;'.  .,:,',;,,.                                      //
//                                                 .:c...           ..                                        //
//                                                   .                                                        //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Flower is ERC721Creator {
    constructor() ERC721Creator("Black & White Flora", "Flower") {}
}