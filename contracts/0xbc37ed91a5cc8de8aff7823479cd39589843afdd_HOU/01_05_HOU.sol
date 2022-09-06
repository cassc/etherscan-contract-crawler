// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hou Media Arts
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    NK0KNMMMMMWK00NMMMMMMMMMMMMMMMMMMMNKOdlc::::::::cccc::::;;;;;:cok0NWMMMMMMMMMMMMMMMMMMNK0KWMMMMMWK0K    //
//    x..'OMMMMM0;..dWMMMMMMMMMMMMMMN0dc,',:lxO0XNWWWMMMMMMMWWWNX0kdl;'.':oOXWMMMMMMMMMMMMMWx..,OMMMMM0,..    //
//    d. .kMMMMM0'  lWMMMMMMMMMMMN0o,..;d0NWMMMMMMMMMMMMMMMMMMMMMMMMMWXOo;...ckNMMMMMMMMMMMWd  .OMMMMMO. .    //
//    d. .kMMMMM0'  lWMMMMMMMMMNk;. 'oKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0o.  'dXMMMMMMMMMWd  .OMMMMMO.      //
//    d. .kMMMMM0'  lWMMMMMMMW0:  .oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKo.  'kWMMMMMMMWd  .OMMMMMO.      //
//    d. .kMMMMM0'  lWMMMMMMWx.  ,OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO,  .oNMMMMMMWd  .OMMMMMO.      //
//    d. .kMMMMM0'  lWMMMMMWx.  '0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0,   oNMMMMMWd  .OMMMMMO.      //
//    d. .kMMMMM0'  lWMMMMM0'  .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx.  .kMMMMMWd  .OMMMMMO.      //
//    d. .o00000d.  lWMMMMWd   ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX;   lNMMMMWd  .OMMMMMO.      //
//    d.            lWMMMMNc   ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc   :XMMMMWd  .OMMMMMO.      //
//    d.  ;ooooo:.  lWMMMMNc   ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc   cNMMMMWd  .OMMMMMO.      //
//    d. .kMMMMM0'  lWMMMMWd.  .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK,  .dWMMMMWd  .OMMMMMO.      //
//    d. .kMMMMM0'  lWMMMMMK;   cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd.  ;KMMMMMWd  .OMMMMMO.      //
//    d. .kMMMMM0'  lWMMMMMWO'  .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk.  'OMMMMMMWd  .OMMMMMO.      //
//    d. .kMMMMM0'  lWMMMMMMWO,  .lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd.  ;0WMMMMMMWd  .OMMMMMO.      //
//    d. .kMMMMM0'  lWMMMMMMMMXo.  'xXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNO;  .dXMMMMMMMMWd  .OMMMMMO.      //
//    d. .kMMMMM0'  lWMMMMMMMMMWKo'  'o0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd;..,dKWMMMMMMMMMWd  .kMMMMMO. .    //
//    d. .kMMMMM0'  lWMMMMMMMMMMMWXkl'..,lx0NWMMMMMMMMMMMMMMMMMMMMMMNKko;..,lONMMMMMMMMMMMMMk.  ;xOOOk;  .    //
//    d. .kMMMMM0'  oWMMMMMMMMMMMMMMMN0xc;'',:coxkOKKXXXXXXXKK0Oxdl:;,,;lxKNMMMMMMMMMMMMMMMMXl.         .o    //
//    XkxkXMMMMMNOxxKMMMMMMMMMMMMMMMMMMMMWX0kdoc:::::::::::::::ccloxOKNWMMMMMMMMMMMMMMMMMMMMMW0xdooooodkKW    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNNNXXXNNNWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMNddNMMMMKcoXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK0NMMMMMMMMMMMMM    //
//    NNXNWNNWMMMWNXXWMMMMMWNXNK;:XMWNNKkOWMMMMWNNNWMMMMMMMMMMMMMMMMWNXNWMMMMMWNNWWNXNMWNXc,kNNNWMMMWNXXXX    //
//    ;dl:oo:xWW0lloocdXMWOccodl':XMNkol;oNMMMW0dolldKMMMMMMMMMMMMMMXkoollOWMWOl:ldol:xXkl'.:ooxXMWOcloood    //
//    .Ok,dK;:X0;;OXKd,oW0;:KWWk':XMMWW0;:NMMMMWXKOo'lNMMMMMMMMMMMMMWNK0k:,OMMWO',0WNdoXWNl,OWWWWMNc.o0XNW    //
//    '0O;xK;:XO',dddolxWk'oWMMK;:XMMMMK;:NMMW0llddl.:XMMMMMMMMMMMMNdlodd;.xMMM0,cNMMMWMMWl,OMMMMMMKxoollo    //
//    '0O;xK;:XXc,d0XXXWMK:;OXKd.:XMNXKk';OKNNl'xXKx';0WMMMMMMMMMMMO,cKX0c'oNWXx':0XWMMMMWd'lKXXNMWXKXX0c.    //
//    ,0O:kX:cXMKl'',,c0MWO,.,;c,cXMO;,'..',xNk,';;c;.:0MMMMMMMMMMMXc.,;:c'.dOc...'lXMMMMMXc.',;kWXl',,'.;    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract HOU is ERC721Creator {
    constructor() ERC721Creator("Hou Media Arts", "HOU") {}
}