// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Spotlight #1: LETHAL
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    MMMMMMMMMMMMMMMMMMMMMMNkolool;xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMO;lXWMNo;OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMXl:KMMMKccXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMM0:oNMMMk;dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMWx;kWMMNo;kNNNNNNNNXXXXXXKKKKKKKKK0000000OOOOOOkkkkxxxkOKNWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWOolc,:KMMMKc;cc:::::::;;;;;;;;,,,,,,,,,'''''''''''''''.''',:ldxOKNMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWx'''''oNMMWO;';;;;;::::::::cccccccclllllllooooooooddddddc,:oc,'';kWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMO,''lo;xWMMNd,dKXXXXXXXXNNNNNNNNNNNNWWWWWWWWWWWWWWWWWWWWO,oNNo'',kMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMM0:''l0l:0MMMKccKWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW0;cXXl'';0MMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMXc'':K0:lNMMMO;dNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWK::KKc''cKMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMNo'';OWx;xWMMWd;OWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWXc;00;''lXMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWd'',kWXl:0MMMKccKWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWXl;Ok,''oNMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMk,''dNW0:lNMMMO;oNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNo,kx,',xWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMXo,''l0K0l,xWMMNd;x00000000000000KKKKKKKKKKKKKKKKKXXXXXXKo,do'',xWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMNk:'',;clllc,:0MMMKc;x0OOOOOkkkkkxxxxxxxddo:;::::::::::::::,';;,'';oKWMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMW0l,'',:llllllc,lXMMMO;dNWWWWWWWWWWWWWWWWWWNd,;cllllllcccccc;',;;;;,'';dKWMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMXd;'',:cllllllll:,xWMMWd;kWWWWWWWWWWWWWWWWWKl,:lllllllllllll:,;clc:;;,''';xXMMMMMMMM    //
//    MMMMMMMMMMMMMMNk:''';clllllllllc;,:0MMMXccKWWWWWWWWWWWWWWW0c,:lllllllllllll:,;cllllc;;;,''':kNMMMMMM    //
//    MMMMMMMMMMMMW0l,'',:lllllllllc;;dk:lXMMMO;oNWWWWWWWWWWWWNk;;cllllllllllllc;,::cllllllc;;;,'',cONMMMM    //
//    MMMMMMMMMMMXd;'',:clllllllllc;cONWx;xWMMNd;kWWWWWWWWWWWNd;;cllllllllllllc;,xXOl:cllllllc;;;,'',lOWMM    //
//    MMMMMMMMMNk:''';cllllllllll:;dXWWWXo:0MMMKccKWWWWWWWWWXo,:lllllllllllllc,;xNWWNkc:cllllll:;;,,'',l0W    //
//    MMMMMMMW0l,'',:llllllllllc;cONWWWWW0:ckOkd:oXWWWWWWWW0c,:lllllllllllllc,;kNWWWWWXxc:cllllll:;;,,'',d    //
//    MMMMMMXd;'',:clllllllllc;;oXWWWWWWWW0xdodxONWWWWWWWWO:,clllllllllllllc,:OWWWWWWWWWKd::llccc::,,,''';    //
//    MMMMNk:''';cllllllllllc;cONWWWWWWWWWWWWWWWWWWWWWWNKx;;clllllllllllll:,:0WWWWWWWWX0ko::cccc:;,,''''';    //
//    MMW0l,'',:lllllllllll;;oXWWWWWWWWWWWWWWWWWWWWWWWXo;,;clllllllllllll:,cKWWWWWX0kol::clllcc:;;,;::,'';    //
//    MXd;'',:cllllllllllc;:ONWWWWWWWWWWWWWWWWWWWWWWWKc,,:llllllllllllll:,lKWWX0kdl::clllc:;;;;';ccllc;'';    //
//    O:''';clllllllllll:;oKWWWWWWWWWWWWWWWWWWWWWWWWO:,:lllllllllllllll;,o00xol::clllc:;;;cok0d,:llllc;'';    //
//    ;''',:::ccccllllc;:kNWWWWWWWWWWWWWWWWWWWWWWWNx;;cllllllllllllllc;';ll::clllc:;;;cdkKNWWWk,:llllc;'';    //
//    ,'',;;;;;;;;;;;;',lkO0KKXNNWWWWWWWWWWWWWWWWXo,;cllllllllllllllc;,;:clllc:;;:ldkKNWWWWWWWk,:llllc;'';    //
//    ;'';llllllcccc:::;;;;;;::clloddxkO0KXXNNWWKl,:lllllllllllllllc;,:llc:;;:ldOKNWWWWWWWWWWWk,:llllc;'';    //
//    ;'';lllllllllllllllllllcccc:::;;;;;:::cllo:',::cccccllllllllc,,;:;,,;':0WWWWWWWWWWWWWWWWk,:llllc;'';    //
//    :'';cllccllcccllllllllllllllllllllllcccc::::;;;;;;;;;;;;;;:;,',,;;:cc,cKWWWWWWWWWWWWWWWWk,:llllc;'';    //
//    :'',cll:xNXKd:llccddoocclllccclllllllllllllllllllccccc::::;,,:cclllll,cXWWWWWWWWWWWWWWWWk,:llllc;'';    //
//    c'',cll:xWMMOcclccOWWNOccccxkxxoclllcccccclllllllllllllllll::llllllll,cXWWWWWWWWWWWWWWWWk,:llllc;'';    //
//    l'',cll:xWMMOccllclKMMWk::kWMMWkckNXK0OOkxoccllccccccclllll::llllllll,cXWWWWWWWWWWWWWWWWk,:llllc;'';    //
//    l'',cll:dWMMOcclll:oXMMNdxWMMM0::0MMMMMMMMNOlccck000Oo:llll;:llllllll,cXWWWWWWWWWWWWWWWWk,:llllc;'';    //
//    o'',:ll:dNMM0ccllll:xNMMWWMMMKl:cOMMMXOOXMMMKo;c0MMMMOcclll;:llllllll,cXWWWWWWWWWWWWWWWWk,:lllll;'';    //
//    d'',:ll:dNMM0ccllllcckWMMMMMXocccOMMMk;;lKMMMO;cKMMMMO:clll;:llllllll,cXWWWWWWWWWWWWWWWWk,:lllll;'';    //
//    x''':ll:oNMM0c:cccllcc0MMMMNd:lccOMMMKxdkXMMM0::KMMMMO:clll;:llllllll,cXWWWWWWWWWWWWWWWWk,:lllll;'';    //
//    x,'':ll:oXMMWKOkxxdoc;dNMMWx:llccOMMMMMMMMMMNx;c0MMMMO:clll;:llllllll,cXWWWWWWWWWWWWWWWWk,:lllll;'',    //
//    k,'':ll:lXMMMMMMMMMXo,oXMMNd:llccOMMMMWMMMMNx::c0MMMMO:clll;:llllllll,cXWWWWWWWWWWWWWWWWk,:lllll;'',    //
//    O,'';llccoxkk00KXNWNd,oXMMNd:llc:OMMMKodKMMWkc:c0MMMMO:clll;:llllllll,cXWWWWWWWWWWWWWWWWk,:llccc;'';    //
//    O;'';lllllc::codddooc:cx0KKo:llccOMMMOc;oXMMWk;c0MMMMO:clll;:llllllll,cXWWWWWWWWWWWWWWWWx,,:c:;c;'',    //
//    0;'';clllclxKNWMWNKkoc:ccclccccc:o0KXkcc:dNMMNo:0MMMMO:cllc;;llllllll,cXWWWWWWWWWWWWXOxdoox0Nx;:;'',    //
//    0;'';cllcoKMMMMMMMMMWOlclllccxkxdc:clcclc:oO0KOoOWMMMO:cllc;;llllllll,cXWWWWWWWNKOxdodk0NMMMMk;c;'',    //
//    K:'';clcc0MMMWKkkOXN0dcclll:kWMMWOcclll:lxdol:ccldddxo:lllc;:llllllll,cKWWWNKkdoddkKNMMMMMMMMk;c;'',    //
//    Kc'',cl:oXMMMOc:ccllccllll:oXMMMMNd:lll:kMMWNd:lllllccllllc;;llllllll,c00kdodxOXWMMMMMMMMMMMMk;c;'',    //
//    Xc'',cl:lXMMWx:llllllllllcc0MMMMMMKlcll:kMMMWx:lllllllllllc;;llllllc:,;ldxOXWMMMMMMMMMMMMMMMMk;c;'',    //
//    Xl'',clccOMMM0lclllccllll:xWMMWWMMWk:ll:kMMMWx:lllllllllllc;;llc:::cok0NWMMMMMMMMMMMMMMMMMMMMk;:;'',    //
//    No'',cllcl0MMWKdlclddcclclKMMMOdXMMXo:l:xMMMWx:lllllllllllc;;ll;ckKNMMMMMMMMMMMMMMMMMMMMMMMMMk;c;'',    //
//    No'',:lllclOWMMWNKXWW0o::OMMMMKOXMMMOcc:xWMMWx:lllllllllllc;;lc;dWMMMMMMMMMMMMMMMMMMMMMMMMMMMk;c;'',    //
//    Wd''':llllccd0NMMMMMMMXldNMMMMMMMMMMNd::xWMMWx:lllllllllllc,;lc;dWMMMMMMMMMMMMMMMMMMMMMMMMMMMk;c;'',    //
//    Wx''':llllllccoxO000OxccKMMMNOOKXNMMMKl,xWMMWx:cccllllllllc,;lc;dWMMMMMMMMMMMMMMMMMMMMMMMMMMMk;c;'',    //
//    Mx,'';lllllllllcccccccccdxkko::ccoKMMWk;xWMMMXOkxxddolccclc,;lc;dWMMMMMMMMMMMMMMMMMMMMMMMMMMMk;c;'',    //
//    Mk,'',;;;;;:cccllllllllllccccllllcokO0OcdWMMMMMMMMMWNX0o:lc,;lc;dWMMMMMMMMMMMMMMMMMMMMMMMMMMMk;c;'',    //
//    MO,''o00kxdol::;;;;::cclllllllllllcccccccdxxk0KXNWMMMMWd:lc,;lc;dWMMMMMMMMMMMMMMMMMMMMMMMMMMMk;c:'',    //
//    MO;''oNWWWWWWXK0Okdolc:;;;;::cccllllllllllccccclooddxkkl:lc,;lc;dWMMMMMMMMMMMMMMMMMMMMMMMMMMMk;c:'',    //
//    MO;''oNWWWWWWWWWWWWWWNXK0kxdol::;;;;::ccllllllllllllccccllc,;lc;dWMMMMMMMMMMMMMMMMMMMMMMMMMMMk;c:'',    //
//    M0:''lXXO0WWWNWWWWWWWWWWWWWWWWXK0Okdolc:;;;;;:ccclllllllllc,;lc;dWMMMMMMMMMMMMMMMMMMMMMMMMMMMk;c:'',    //
//    MK:''cX0:oNW0oloxKKKNWWWWWWWWWWWWWWWWWNXK0kxdolc:;;;;;::cc:,;lc;dWMMMMMMMMMMMMMMMMMMMMMMMWKOdc;c;'',    //
//    MKc''cK0:oNMO;:odOl;0W0dOWNKKNWWWWWWWWWWWWWWWWWXK00Oxdolc:;';lc;dWMMMMMMMMMMMMMMMMMMMWKkdc:::cll;'',    //
//    MXl'':K0:oNMO;;lOKc'dKo'o0l;;ckNKx0WNXNWWWWWWWWWWWWWWWWWNXx;;lc;dWMMMMMMMMMMMMMMMWKkdooxl,:lllll;'',    //
//    MNl'':00:ckKO;:dO0c.:o;'cc;x0d:dk,;0OcOWNkONWNXNWWWWWWWWWW0;,lc;dWMMMMMMMMMMMWKkdddxOXWWk,:lllll;'',    //
//    MNo'';0Xdc:ld:;ldx:;:',,::cKMNo:o;'ld:xWO,;OWx:ckXWXOOKXNW0;,ll;dWMMMMMMMWKkdddxOXWWWWWWk,:lllll;'',    //
//    MWo'';OWWNXXX0kddxoxd,lccd:lOO:cd:cc;;kNo,,oNd;l:oKk:,:cOWO;,lc;dWMMMWKkdodxOXWWWWWWWWWWk,:lllll;'',    //
//    MWd'',kWWWWWWWWWWWNNX0K0kX0l:;cOk;xk,,kO;:::0x:Ok:cl:cxkXWO;,lc;dNKkdc:dOXWWWWWWWWWWWWWWk,:lllll;'',    //
//    MWx'',cxO0KNWWWWWWWWWWWWWWWNXKNWKx0Xo;xo,;;,dd:kd;:l:,:dXMO;,lc;:l:::,cXWWWWWWWWWWWWWWWWk,:lllll;'',    //
//    MMk,'',;;;:clodkOKXNWWWWWWWWWWWWWWWWNKK0OK0odd;,;o0k:cxOXWO;,ll::clll,cXWWWWWWWWWWWWWWWWk,:lllll;'',    //
//    MMk,'';lllcc::;;;;:codxk0KNWWWWWWWWWWWWWWWWNNX0OKNWKo::cOWO,,clllllll,cXWWWWWWWWWWWWWWWWk,:lllll:'''    //
//    MMO,'';lllllllllllcc::;;;:clodkOKXNWWWWWWWWWWWWWWWWWWNXKXWO,,clllllll,cXWWWWWWWWWWWWWWWWk,:lllll:'''    //
//    MMO;'';llllllllllllllllllccc:;;;;:cldxk0KXNWWWWWWWWWWWWWWWk,,clllllll,cXWWWWWWWWWWWWWWWWk,:lllll:'''    //
//    MM0;'';clllllllllllllllllllllllllcc::;;;::lodxO0XNWWWWWWWWk,,clllllll,cXWWWWWWWWWWWWWWWWk,:lllll:'''    //
//    MM0:'';clllllllllldxxxddddddddxxxxdllllllcc:;;;;:clloxk0KXx,,clllllll,cXWWWWWWWWWWWWWWWWk,:lllll:'''    //
//    MMKc'',cllllllldkxdoodddddddddddooodxxdlllllllllccc::;;;;:;',clllllll,cXWWWWWWWWWWWWWWWWk,:lllll:'''    //
//    MMXc'',clllloxkdloxkOkkxxddoodxxxxdooodxkdlllllllllllllllc;',clllllll,cXWWWWWWWWWWWWWWWWk,:lllll:'''    //
//    MMXl'',cllldOdcoOOkkkO00K0Okolddxxkkkxdlodkxolllllllllllll:',clllllll,cXWWWWWWWWWWWWWWWWk,:lllll:'''    //
//    MMNo'',cllxOll00dd0NWWWWWWWWXOXWWWNK0OOkxoldkxolllllllllll:',clllllll,cXWWWWWWWWWWWWWWWWk,:lllll:'''    //
//    MMWd'',:lxOcoKxcxNWWWWWWWWWWXxOWWWWWWWN0kkkocdOxllllllllll:',clllllll,cXWWWWWWWWWWWWWWWWk,:lllll;'''    //
//    MMWd'',:dOllKx,oNWWWWWWNNWWWNddNWWWWWWWWN0xxkocxkollllllll:',clllllll,cXWWWWWWWWWWWWWWWWk,:llc:;,'''    //
//    MMWx''':Ox:OO;:OXXWWWWWKdkNWWdc0WWWNNWWWWWNkokxcoOOxllllll:',clllllll,cXWWWWWWWWWWWWWWWWk,;:;,''':ok    //
//    MMMk,''lOllKoc0WX0OOKWWWOlxNWx,xWWKoxNWWWWWWOcoOlcdOklllll:',clllllll,cXWWWWWWWWWWWWWWN0l'''',:dOXWM    //
//    MMMk,'';c;lxckWWWWXOddxKNX0XWk,cKWxcOWWWWWNX0x:lOd;ckkllll;',clllllll,cXWWWWWWWWWWWXOd:,'',cd0NMMMMM    //
//    MMMKo:;'''',,coxO0XWN0dclx0NWO;,kWXXWNX0kddk0NKolOKdckklll;',clllllll,cXWWWWWWWWXko:,'';lx0WMMMMMMMM    //
//    MMMMWNKOxdl:;'''',:loxOko:;cdd;'l00kdc::okXWWWWNxokOocOxll;',clllllll,cXWWWWNKkl;''';lkKWMMMMMMMMMMM    //
//    MMMMMMMMMMWNKOxdl:;'''',::,''';cc;,',cxKNWWWWWWWNx:xOcoOoc;',clllllll,cXWN0xl;'',:okXWMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWNKOxdl:;''''',cc,'ckXWX00KNWWWWWX0xOx:kkc;',clllllll,:xdc,'',:dOXWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWNKOxdl:,'''',:col::ckNWWWWWWOkOcdOl;',clllllc:,'''',cd0NMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOxdl:;'''',;coxO0XWM0x0olOo;',cllc:;,''';lx0NMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOxdl:;'''',:loccdccOd;',::;,''';lkKWMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNK0xdl:;'''''',::,'''''':okXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOkxdl:;''''',:dOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0xl;,:xXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SPOTLIGHT1 is ERC1155Creator {
    constructor() ERC1155Creator("Spotlight #1: LETHAL", "SPOTLIGHT1") {}
}