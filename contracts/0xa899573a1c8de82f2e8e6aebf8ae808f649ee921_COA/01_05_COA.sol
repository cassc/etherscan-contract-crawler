// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Chronicles of Anarchy
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//                                                ..                                      //
//                                              ........;::,.                             //
//                                 ..',:cloollccc:,,,';c;,oxo;.                           //
//                            ..':odkkO00OOOOOOOOOkxl,:dx;.o0Oc.                          //
//                         .'lxkkOOO0000OOkkkOOOOOOOOxc,cc.lOOo.                          //
//                        'okOOOOOOOOOOkkkOOOOOOOOOOOOOl':cclxOc.                         //
//                      .cxkOOOkOOOOkkOOOOOOOOOOOkkkOOKd,lxl,:kx'                         //
//                     .oOOOOOOOOkOOOkkOOOOOOkkkkkOO00Kd,oxlldkk:                         //
//                     :O0OO0OOOOOOOOOOOOOOkkkkkOOO00KKo,o0KKOkOx,                        //
//                    .lOOOO0K0OOOOOOOOOOOOOOOOOOOO0KK0l:x0KK0OOOc.                       //
//                   ..;x0OOO000000OOOOOOOOOOOOO00KKK0o;oO00KK0OOl.                       //
//                   .''oOkkOOOOOO00OOOOOOO000000000OkkxkO00OO000d.                  .    //
//                   .,.:Ol;okxolllcoxxkO0KKKkdl;;lk0OkOOOK00OOkOo.                 .,    //
//                    ...dkc;;;,',;'..'.,dOxc'... .o0OOOO0xoO0OOk;                .',,    //
//                       'dd:''. ........cc.....  .o0OOkOx,.cOOOd.               .,;,,    //
//                      .;ccc:'...',,,;cll;  ...  ,kOkkOd'  'xOOl.             .';,,,;    //
//                     .:::lllolccccc,,:;cc.    ..:kOkOd'  .'lOO:.            .';;;;,.    //
//                    .;::cccclcccccc,;:,,c:..... .;lkk:     .lOc....        ..',,;,.     //
//                     .'clllc::;'':l:;:;;;:,..     .;d:.     .:l,'',..    ......'..      //
//                      .';;,..... .,:lol:;:.         .::.  ...';;,,','.  .,'.....        //
//                         ........,:coooc;.           .,. .,;,''',,,;:,.',,,'''.         //
//                         ';:::::ccccll:'.          ..''. .,;;,''',,;c::;,',,..          //
//                         ,lccccc:::;,'         .;l;'dx;...',,;,''',,;;,,,,,.            //
//                         .;:;;::;,..... ....    ;ko.;ko''''',,;;,'',,;;;;,.             //
//                          .......   .:.         .lkc.:ko;'''',;;::::clodool,.           //
//                                    .''.         .lko;,lxo:ccloodddddddxxddxc.          //
//                                     .,.       .  .:xkl:oxdddddddoolcc::c::::'          //
//                                     ';. ..........;oxdddddxd:;;,;;;,''',,''''.         //
//                                   .,,.  .......;lddddodxdlloc'..',,;,,'',,,,;;.        //
//                                  .,.        .,ldddlc,..lOo.;kx,..',,;,,',,,,,..        //
//                                .,,.      .;clddo:,'.   ;kx,.dOc. .',,;,,,,,,.          //
//                               .;'.     .,ldddl;....    ;kx,.oOl. ...';,;;;;,.          //
//                             .,,.      .codoo:.  ..     :Ox'.dOc.  ....,;;'..           //
//                            .;.      ..,,,;'..  .'.    .cOd.'xO:    .'.''.              //
//                          .,,.      .',.''.     ...    .cOd.'xk;    .,,..               //
//                         .,,       .:oooc.      ...     :Od.'xk:    .'..                //
//                         ,,.      .;oooo,        ..     ,kx'.oOc.  ..'.                 //
//                        .;.      .;olol,.       ...     .dk;.cOo.  .,.                  //
//                       .,'       .cooo:.       ....     .oOc.;kd. .'.                   //
//                       .,.      .;oddo,        .....    .lOl.,kx' .'.                   //
//                                                                                        //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract COA is ERC721Creator {
    constructor() ERC721Creator("Chronicles of Anarchy", "COA") {}
}