// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: XKNIGHT RENDERS 721's
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                           ...       ..                                                                                                 //
//                                                            ..      ..'.                                                                                                //
//            ..','..                                                .col;......                                                                                          //
//           .:l::::c,.                                           ...;dkOOxc........                                                                                      //
//           .:l;,,:ol..                                       ......;clloxxo,........ ..                                                                                 //
//           ..',;::;'.                                      ........,;:::ccllc;,..........                                                                               //
//                ..                                        .........,clc:;;;;;;:;,'..........  ........                                                                  //
//                                                          ......,:ok0XXKOkdl:,'',,,''............',,,,'...                                                              //
//                                                         ......;xXXXXNNNNNXX0Oxdl:;,'''......':lddddxxddl:'..                                                           //
//                                                         .....'lKNXNNWNXXXXXXXXXXK0kxxoc;'':oxxdllcccccloxxc..                                                          //
//                                                         .....,xXXKXXXXXNNNNNNNNNNXXXKKK0kdxxocc:;;,''''',;l:..                                                         //
//                                                          ....c0XKKKXX0kkkOO00KKK0kddoodkKOo:,'....       ..:;.                                                         //
//                                                          ....;kKKKK0d;''',,,;;;;;::;;;:xkc....            .':'                                                         //
//                                                           ....cOX0d;.............,;,,,:xo'....             .:'                                                         //
//                                       .....                 ...ld:...............,,,,,:dc....             .':'                                                         //
//                                      ..:d;..                  ...................','',:l;...              .;;.                                                         //
//                                      ..,;...                          ...   ..  .',''';c:...             .,;..                                                         //
//                                        ..                                       .'''''',c:..           ..,;..                                                          //
//                                                                                 .''.'''..;:'.....    ..,;'.                                                            //
//                                                                                 .''..''...',,,,,'..'',,'.                                                              //
//                                                                                 .''..'..   ...''''''..                                                                 //
//                                                                                 .''.....                                                                               //
//                                                                                 .....''.                   .                                                           //
//                                                                                 .'...''.            .   ...........                                                    //
//                                                                                 .,,',,'.           ... .......''.....                                                  //
//                                                                                 .,,,;;,.             ......';oOOl,....                                                 //
//    ........................................                                    ..,,,:c;.               ....'cKWW0c'....                                                //
//    ;,,,,,,,,,,,,,,,,,,'''''''''''''''''.......................                 .';::cl:.               .....,okko,.....                                                //
//    llllllllllllllllllllllccccccccccc:::::::::;;;;;,,,,,'''''....................,cclloc'. ...  ....  .........''......                                                 //
//    kkkxxxxxxxxkkkkkkkkkkkkkkxkkxxxxxxxdddddddooooollllllcccc:::::;;;;;,,,,,,,,'':lllool;..................................                                             //
//    xxddxxxxxk0KKKK0kkkO000OOO0KK0OkO0Okxxkkkkkkkkkxxxddxxxxxxddddoooooolllllllc::lllodlc;;;,,,,,;;;;;;,,,'''......................                                     //
//    cclodxxkxxxkkO0OxoloxkOOkxkkxoldOOkxdxxddxxxxkkkdlllddkOOkxodxxddddolloddocc;;:cclollllc:;,;cc:;,;::::;,,,,,''.....................                                 //
//    :codddddl:clldxdl:;::ccoxxddocclolllodl:cllloool:;;:ccldolc:cdoc:::;;;:cc:;;,;:::clclol:;'.',''..''',,''',,'......................                                  //
//    xkO0K0OxolodkOkdooooooodk0K0kdxxxxxddxxddddkkkxocldkxocclododxxlcoc;,,,;cccc:::::ccccc;,,,,;,''.,;,',,'',,'................  ..  .                                  //
//    0KXXXKOOkk0KKKOxk0K0000KKXX0kk0KK0OkO0K0O0KKKKOkkk00Okxddxkkxxxxxxdlccloodoocclccllcll:cc:;;;;;;clc::cc:;;,.......'.....'..  ..                                     //
//    0000000OOO000OOOO0000000000OOOOOOOOOOOOOOOOOOkkxxkkxxxddddddoodddddoooddddooooxddxxollcccc:;;:::cccc:cc::;;;,,,''.''.............   ....                            //
//    kkkxxkkxxxxxxxxxxxxxxxxxxxxxxxxxxddddddddddddooooollllccccccc::cccccccccllloxO00000kdlcc:;;;;;;,,;;;;;;;;;;,,,''..................  ...                             //
//    ooooooooooooooooollllllllllllllllcccccccc::::::;;;;;;,,,,,,,,,,,,,,,,;;:clokXNNNNNNXOdoc;,,''''''''''''',,''''.........                                             //
//    c::::cc::::::::::;;;;;;;;;;;;;;;;;,,,,,,,,,''''''.....................':ccoOXXNNNNNX0xol:,........................                                                  //
//    ,,,,,,,,,,,,,,,,'''''''''''''.................................  .......',;clodxkkkkdol:;,........... ...........                                                    //
//    '.......................................                        .........'',,;;:::;;,,'..........                                                                   //
//    ............................ ..                                 ..........'',,,,,,,,''...........                                                                   //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract XKR721 is ERC721Creator {
    constructor() ERC721Creator("XKNIGHT RENDERS 721's", "XKR721") {}
}