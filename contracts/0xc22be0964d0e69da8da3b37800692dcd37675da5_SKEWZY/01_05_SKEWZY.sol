// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kangasjon
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//    #   ██████╗ ██╗  ██╗ █████╗ ███╗   ██╗ ██████╗  █████╗ ███████╗     ██╗ ██████╗ ███╗   ██╗    //
//    #  ██╔═══██╗██║ ██╔╝██╔══██╗████╗  ██║██╔════╝ ██╔══██╗██╔════╝     ██║██╔═══██╗████╗  ██║    //
//    #  ██║██╗██║█████╔╝ ███████║██╔██╗ ██║██║  ███╗███████║███████╗     ██║██║   ██║██╔██╗ ██║    //
//    #  ██║██║██║██╔═██╗ ██╔══██║██║╚██╗██║██║   ██║██╔══██║╚════██║██   ██║██║   ██║██║╚██╗██║    //
//    #  ╚█║████╔╝██║  ██╗██║  ██║██║ ╚████║╚██████╔╝██║  ██║███████║╚█████╔╝╚██████╔╝██║ ╚████║    //
//    #   ╚╝╚═══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚════╝  ╚═════╝ ╚═╝  ╚═══╝    //
//    #   ARTWORK BY JONATHAN ASKEW                                                                 //
//    ------------------------------------------------------------------------------------------    //
//                                                                                                  //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXK0kxxkxxkxk0XXXXXKK0kkkxkOKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXOddl,ckl,lo:cOXXX0do::oc:dloOXXXXXXX0OkkOkOOOOO0KKXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXxoOdckXOl:;,;lolc:lxdOKxlc::xXXXX0kxxkkkkxxxxxxkOkk0XXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXKkxxx0Kx:;;;.     'lxXN0l;:dkOK0xdkKXKOxdoodkOdcokxd0XXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXKKKXXXXXXXKOlll:;:l'      .'oXKxl;,'..:dkKK0xooddl,';odc;lOxdOXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXKOxxxdx0XXXXKOd;'ckOddc'',,,',:cooc,.   .dXXOo::d0k:....;cllldooOXXXXXXXXXX    //
//    XXXXXXXXXXXXX0kdxxo:;,cOKKKkoxxxKNX0OO00KKKK00kxdc,.   :KNOl';kXd.     ..',;ldOKXXXXXXXXXX    //
//    XXXXXXXXXXXXKdoolkKOdc,,,.'''ckOd:;cllllodxOKXNNNOl,.  ;OKx:.lKk'   ..',;lox0XXXXXXXXXXXXX    //
//    XXXXXXXXXXXX0oxx:lKWXxc'.    .coc,.'..   .';::lkXXd;. .'lOx;.,;.  .ckKNXKKOkxOKXXXXXXXXXXX    //
//    XXXXXXXXXXXXKxlxkkO0Oxddl:::cd0Oxlcc;'.  ,dd'..,kXk:.  .lOx;.   .ck00Okkkk0KOdx0XXXXXXXXXX    //
//    XXXXXXXXXXXXX0dlodkkxddodkOKXNNKOdc,. ..lxo;.  .lOd,.  ,oOk;  .;xOxoc;,,,,:lkOxd0XXXXXXXXX    //
//    XXXXXXKkkOOOOOO0KK0kxddocclddoc,...    ,c,.   ..:o;.   'cl;. .ckkd::l'     .;lkxd0XXXXXXXX    //
//    XXXXKxcdXNXXX0koc:;;;,'';;'......,;.           ..'..       .,dKOo,;xo.    .oo'oOoxXXXXXXXX    //
//    XXXKdcdXWWXOl,.....',,. ....   ..,;,,;;;::ccooooooolcc:'. .'cdd;....    ,lkKo'lOddKXXXXXXX    //
//    XXXOokX0olo,            .    ..,cdkO000O00KKKKKKKKK000Oko,..... ..,:cclokKXx',dKOdxkkOKXXX    //
//    XKX0dxOl,;,.       ';;;:;,,cokO0000K0K0KKKKXXXXXXXXXXXXX0o'    .;d0XXXNXOxo:cdxXNKxc:ldOXX    //
//    XXXX0xo:''.      .:oxl'  ;OKK0000000000000KKKXXXKK00KXXXX0c.   .,;:;;cokOc.'cdKKkdko,:cxXX    //
//    XXXXXK0kxkd;.  'lxxkd,. .oKKK0OkOO0KK00000000kd:,'..,lOKXXO:.     ..;c::c'  .;0x.'dl''c0XX    //
//    XXXXXXXXXXXX0xkO0X0l..  ;0XK0d;'.,:lk0K00000dc'       ,kKXKo.    .,::ll;,;. .;O0dddc,;xXXX    //
//    XXXXXXKOOOO0000KK0o'   .lXX0l.      .o0K000Kkd;       .lKXN0:.   .'',:lo;'cc,,ldddk0d,:OXX    //
//    XXXXXOkkkkxdddddo:'.    :KNKl.      .'o0KKKKKKo.    ...lKNWNx'      ...;,.'dxlloollO0d:dKX    //
//    XXXXOxd::c'.cdooodc. .. .dNNKx,.  ..''cOXKKXXNO;  ..',,dNWWWO;.   ..,:,',. .'',:ll;cl:lOXX    //
//    XXXXxdxc:'.,OXXXXX0;,Od. ;KWWN0:..',,,c0WNNNWWNo''';cdxKWMMWk,. .;dkk00OOd:cod:..,,;cd0XXX    //
//    XXXXOxo:''lOXXXXXXXxxNk. .dWWWWO:;:;;cd0WWWWWMWklxxk0XXNMMMNx,.  .,:lokKXK0O0KKkdddkKXXXXX    //
//    XXXXXK0OO0XXXXXXKK0xOXk'  ,0WMMWdckkk0KKWMMMMMM0oOWWWNNWMMMXxc'       .;d0NKo,,lOXXXXXXXXX    //
//    XXXXXXXXXXXKOkOkkdlool,.   cNMMM0lkWWWNXWMMMMMMNkxO0KNWMMMMKk0d,,.      .l0Nx.  ,OXXXXXXXX    //
//    XXXXXXXXX0kkOOxdl,',;;'.   .kWMMW0kOO0KNMMMMMMMMWNXKNWMMMMWOkOdd0k'     .'dKd.  :0XXXXXXXX    //
//    XXXXXXXXOxdoO0o',ldkKOc'    ;KMMMMWWWXKXXXNXK00OONMMMMMMMMNolxOXXX0o,..  .cOd';xKXXXXXXXXX    //
//    XXXXXXXOdkl'oOo'lX00Xd,;.    :KWMMMMMO:lxxkkxxkkx0WMWNXK0OxdOKXXXXXXK0kd:.'dOOxdxOKXXXXXXX    //
//    XXXXXXXOoxkdxd:,dXKOkl,;.    'dOKNWMMN0O0K0kddolccc:;cxkOOKXXXXXXXXXXXKXk'.cdO0o:lx0XXXXXX    //
//    XXXXXXXXOkkxlloxKXKkxd:'..;co0KOkkOOOOOOOk;         'ox0XXXXXXXXXXXXXXXKd'';;;okdloOXKXXXX    //
//    XXXXXXXXXXKKKKXXX0ooKNO:..dXXXXXXXK00KXXXXl  ..,:ldkk0kd0XXXXXXXXXXXXXX0;..';:cllokKXXXXXX    //
//    XXXXXXXXXXXXXXXX0l'lXWNo..cKXXXXXXXXXXXXXKdckO0XWWWWXOdx0XXXXXXXXXXXXXXKxc::clodx0XXXXXXXX    //
//    XXXXXXXXXXXXXXXX0lckNNXd,.:0XXXXXXXXXXXXX0xkXXXK0KK0OO0KXXXXXXXXXXXXXXXXXXKK0KKXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXX0kxxxxxllkKXXXXXXXXXXXXXKKKKXKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXK0000KXXXXXXXXXXXXXXXXXXXKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKKK00KK0KXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX ARTWORK BY JONATHAN ASKEW 0000XXXXXxxxxX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract SKEWZY is ERC1155Creator {
    constructor() ERC1155Creator("Kangasjon", "SKEWZY") {}
}