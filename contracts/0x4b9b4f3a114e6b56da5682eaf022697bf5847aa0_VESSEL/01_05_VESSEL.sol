// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Vessel
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                         //
//                                                                                                                                                                                                         //
//                                                                                                                                                                                                         //
//                                                                                                                                                                                                         //
//                                                                                                                                                                                                         //
//                                                                                                                                                                                                         //
//                                                                                                                                                                                                         //
//                                                                                                                                                                                                         //
//                                                                                                                                                                                                         //
//                                                            A Q U E O U S :  T H E  V E S S E L                                                                                                          //
//                                                                                                                                                                                                         //
//                                                                                                                                                                                                         //
//                                                                                                                                                                                                         //
//                                                                                                                                                                                                         //
//                                                        .......'''',,,,;;;;;;;;;;,,,,''''.....                                                                                                           //
//                                                    ..,;;:cclllooooddddxxxxxxxxxxxxxxxxxdddoollcccc::;,'..                                                                                               //
//                                                    .',;::cclllooddddxxxxxxxxkkkkkkxxxxxxxxxdddddddooolc:'                                                                                               //
//                                                     .,:cccclloodddxxxxxxkkkkkkkkkkkkkkkkkkxxxxxdddoolc:'                                                                                                //
//                                                      .,:ccccllooddxxxxxxkkkkkkkkkkkkkkkkkkxxxxxxdddool;.                                                                                                //
//                                                       .;:cccllooddxxxxxkkkkkkkkkkkkkkkkkkkxxxxxdddool:.                                                                                                 //
//                                                        .;cccllooddxxxxxxkkkkkkkkkkkkkkkkkkxxxxxxddolc.                                                                                                  //
//                                                        .':cccloodddxxxxkkkkkkkkkkkkkkkkkkkxxxxxxdooc'                                                                                                   //
//                                                         .,:ccllodddxxxxxkkkkkkkkkkkkkkkkkkxxxxxxdol,                                                                                                    //
//                                                          .,:ccloodddxxxxkkkkkkkkkkkkkkkkkxxxxxxdol;.                                                                                                    //
//                                                           .;:clloodddxxxxxkkkkkkkkkkkkkkxxxxxxddo;.                                                                                                     //
//                                                            ':ccloodddxxxxxxkkkkkkkkkkkkkxxxxdddo:.                                                                                                      //
//                                                            .,:cllooddxxxxxkkkkkkkkkkkkxxxxdddooc'                                                                                                       //
//                                                             ':cclooddxxxkkkkkkkkkkkkxxxxxdddool;.                                                                                                       //
//                                                             .;cclooddxxxkkkkkkkkkkkxxxxxdddoolc'                                                                                                        //
//                                                             .;cclooddxxxxkkkkkkkkkxxxxddddoolc:.                                                                                                        //
//                                                             .,cllooddxxxxkkkkkkkkxxxxdddoolllc;.                                                                                                        //
//                                                             .,cllooddxxxxxxxkkkxxxxxddooolllcc,.                                                                                                        //
//                                                             .;lllooddxxxxxxxxxxxxxdddoollllcc:,.                                                                                                        //
//                                                             .:llloodddxxxxxxxxxxxddddoollcccc:,.                                                                                                        //
//                                                             .:lllooddddddxxxxxxxxddooollccc:::;.                                                                                                        //
//                                                             ,clllooodddddddddddddoollllcc::::;;.                                                                                                        //
//                                                            .:lllloooooddddddddddoollccc::::::;;,.                                                                                                       //
//                                                           .;lllllloooooooooooooollccc:;'';;::;;,.                                                                                                       //
//                                                          .,cllllllloooooooooollllcc:::;. .';;;,,,.                                                                                                      //
//                                                         .,clolllllllllllllllllllccc:;;,.  .',;,,''.                                                                                                     //
//                                                        .,clolllllllllllllllllllccc::;;,.   ..',''''.                                                                                                    //
//                                                       .;cloolllllllllllcclllcccccc::;;,.    .'''..''.                                                                                                   //
//                                                     .':cloollllcccccccccccccccccc:::;;,.    ..'.....'..                                                                                                 //
//                                                    .;clloollcccccccccccccccc::::::::;;,.     .'.........                                                                                                //
//                                                  .,:cloolllccccccc::::ccccc:::::::::;;;'.    .'........'..                                                                                              //
//                                                 .;clooolllccccccccc::cccccc::::::::::;;;..    .''......'''..                                                                                            //
//                                                ':loooollllccccccccccccccccccccc::::::::;'.     ...'...''',,,.                                                                                           //
//                                               .:looooollllllllllllllllllllllccccccccc::;;,..     ..',;;;,,,;,.                                                                                          //
//                                              .;looooooooooooooooooooooooooooolllllllcc::;;;;'.  ..,;:::::::::,                                                                                          //
//                                              .:odoooddddddddddddddddddddddddddddooolcccc::::::,;:cccccccccc:c;.                                                                                         //
//                                              .codoodddddxxxxxxxxxxxxxxxxxxxxxxxxxddoolcllcllooooollllllllllcc:.                                                                                         //
//                                              .:oddddddxxxxxxxxxxxxxxxxkkkkkkkkkkxxxxxddddddddddddoooooollllll;.                                                                                         //
//                                              .;loddddxxxxxxxxkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxdddddoooooool,                                                                                          //
//                                               'clooddddddxxxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxdddddddooo:.                                                                                          //
//                                               .;clooooddddxxxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxdooolllllc:.                                                                                           //
//                                                ':looooddddxxxxxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxddoolllc::;,.                                                                                            //
//                                                .,clooddddddxxxxxxxkkkkkkkkkkkkkkkkkkkkkkkkxxxdddooollcc:;;'.                                                                                            //
//                                                 .,clooddddddxxxxxxxxxxxkkkkkkkkkkkkkkkkkxxxddddooollcc:;;'.                                                                                             //
//                                                  .,cloddddddddddddxxxxxxxxxxxxxxxxxxxxxxxxddddooollcc:;;'.                                                                                              //
//                                                  ..,cooddddddddddddddddddxxxxxxxxxxxxxddddddooolllcc:;,..                                                                                               //
//                                       ..............,coodddddddddddddddddddddddddddddddddoooolllcc::;,.                                                                                                 //
//                             .........................,coodddddddddddddddddddddddddddooooooolllcc::;,'.                                                                                                  //
//                           ..........................'',coddddddddddddddddoooooooooooooolllllcc:::;,.                                                                                                    //
//                            ......................''',,;:codddddddddddddddooooooooooollllllccc::;;'.                                                                                                     //
//                               ..................''',,;;::lodxxxxxxxxxxdddddddddoooooolllllccc:;,..                                                                                                      //
//                                     .............''',,,;;::cclooddxxxxxxxxxxxxxxxddddoollc:;,'..                                                                                                        //
//                                            ...........'''',,,,;;;:::ccccccccccccc::;;,''....                                                                                                            //
//                                                   ................................                                                                                                                      //
//                                                                                                                                                                                                         //
//                                                                                                                                                                                                         //
//                                                                                                                                                                                                         //
//                                                                                                                                                                                                         //
//                                                                                                                                                                                                         //
//                                                                                                                                                                                                         //
//                                                                                                                                                                                                         //
//                                                                                                                                                                                                         //
//                                                                                                                                                                                                         //
//                                                                                                                                                                                                         //
//                                                                                                                                                                                                         //
//                                                                                                                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract VESSEL is ERC721Creator {
    constructor() ERC721Creator("The Vessel", "VESSEL") {}
}