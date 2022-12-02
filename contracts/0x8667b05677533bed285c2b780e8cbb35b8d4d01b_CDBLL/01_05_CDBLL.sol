// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CDB: LOST LEGENDS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//    WWNXO, ;KWNNKc .kWNNXd..lNWNXk, ;KWNNKc.                                                         :0XNWX: 'kXNWNd..oXNNWO' :0NNWX: 'kXNWNo.                //
//    WXo';dO0NWx,'lk0XW0:':xOKWXl';dO0NWx,'lkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOko,'dNNKOx;.cKWXOkc';OWN0Oo,'dNNKOd;'cKWXOOOOOOOOOOOOO    //
//    lllcdKWKdllclOWXxllllxNWOollcdKWKdllclOWXxllllllllllllllllllllllllllllllllllllllllllllllllllllxXW0ocllo0WXdclllkNNklcllxXW0ocllo0WXdccllllllllllllllll    //
//    .,kWNKOd,.oNWK0x:.:0WX0Ol.,kWNKOd,.oNWK0k:....................................................;x0KNNd''oOKNWO,.ck0XWKc.;x0KWNd''oO0NWO;...............    //
//    XXNW0;.;OXXNXl.'xXXNNx..lKXNW0;.;OXXNXl.'xXXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXk,.cKWXX0:.,OWNXKo..dNNXXk'.cKWXX0:.,OWNXKKKKKKKKKKKKKKK    //
//    WXd;:odONWk:;ldkXWKl;cdx0WXd;:odONWk:;ldkXW0l;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;c0WXkdl::xNNOxo:;oXWKxdc;c0WXkdl::xNNOdo:;;;;;;;;;;;;;;;;;;    //
//    ddc;l0WXkdl;:kWNOdo:;dXW0xdc;l0WXkdl;:kWNOdo:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:odkXWOc;ldxKWKl;cox0NNx;:ldkXWOc;ldxKWKo;;;;;;;;;;;;;;;;;;    //
//    ..xNNXXx'.lXWXXO;.;0WNXKl..xNNXXx'.lXWNXO;.;0WNKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXWK:.,kXXNNo..dKXNWk'.c0XNWK:.,kXXNNo..dKKKKKKKKKKKKKKKKKKKKK    //
//    O0XWK:.:x0XWNo.,dOKNWk,.lO0XW0:.:k0KWNo.,dOKNWk,........................................'xWNK0d,.lXWX0k:.;0WN0Ol''xWNK0d,.lXWX0k:.....................    //
//    WNxllllxXWOlclldKWKdccloOWNxccllxXWOlclldKWKdccllllllllllllllllllllllllllllllllllllllllllcco0WKdllclOWNklllcxXW0ollco0WKdllclONNklllllllllllllllllllll    //
//    Ox:':0WX0kl',xWN0Od;'lXWKOx:.:0WX0kl',xWN0Od;'lXWKOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOKWNo',oO0NWk;'lkOXWKc':xOKWNo',oO0NWk,'lkOOOOOOOOOOOOOOOOOOOOOOO    //
//    ..dXXNNk'.cKXNN0:.,OXNNXo..dXXNNx'.cKXNN0;.,OXNNXo....................................cXNNXO;.;0NNXKl..xNNNXx'.cXNNXO;.;ONNXKl........................    //
//    xkKWKl,:dx0WNd;;oxONWO:,lxkKWKl,:dx0WNd;;oxONWO:,lxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxl;;kWNOxo:,oXWKkdc,c0WXkxl;;kWNOxo:,oXWKkxxxxxxxxxxxxxxxxxxxxxxx    //
//    WNOdoc:dXW0doc:l0WXxol::kNNOdoc:dXW0doc:l0WXxol::kNNOddddddddddddddddddddddddddddddkNWOc:loxKWKl:cod0WNd:codkNWOc:loxKWKl:codddddddddddddddddddddddddd    //
//    KO:.,OWNXKo..dNNXKx,.cXWXKO:.,OWNK0o..dNNXKx,.cXWXKO:..............................;OKXWXl.'dKXNNx'.l0KNW0;.;OKXWXl.'dKXNWx'..........................    //
//    .'o0KNWk,.cOKXWKc.;x0XWNo.'o0KNWk,.cOKXWKc.;x0XWNo.'o000000000000000000000000000000d'.lXWX0k;.:0WNK0l.'xWNK0d'.oNWX0k;.:0WNK00000000000000000000000000    //
//     .dWKdccloONNkccloxXW0lclod0WXd:cooONNkccloxXW0lclod0WXd::c::cc:::::::::::cc::c:oKWKdolclOWXkolccxNWOooc:oKWKdolclOWXkolccc::::c::::::::::::c:ccc:cxNW    //
//     .dWO' ,KWKkxc':OWXOko,,xNN0kd:'lXWKkxc':OWXOko,,xNN0kd:'''''''''''''''''''''''';ok0NWx;,lkOXW0c'cxkKWXo';dk0NWk;,lkOXW0c'''''''''''''''''''''''.  ;KW    //
//     .dWO' ,KNo..oXNNNk'.:KNNNK:.'kNNNXo..oXNNNk,.:KNNNK:.,kNXXXXXXXXXXXXXXXXXXXXXXNO,.;0NNNKc.'xNNNNd..lXNNNO,.;0NNNKc .xNXXXXXXXXXXXXXXXXXXXXXKXXNx. ;KW    //
//     .dWO' ,KNo  oNXl':dk0NNx,,okOXWO:'cxkKWXl':dk0NNx,,okOXWO:'''''''''''''''''';kWN0ko;,dNWKkd:'cKWXOkl,;kWN0ko;,dNX:  .''''''''''''''''''''''':OWk. ;KW    //
//     .dWO' ,KNo  oWK, 'OW0dolcl0WXxolcckNNOolc:dXWKdolcl0WXxolcc:c:::::::::c::ccccloxKW0occod0WXdcclokNNkccloxXWx. :XNkcc::c:::::::::cc::c::cc:. .xWk. ;KW    //
//     .dWO' ,KNo  oWK, 'OWd. lNWX0x;.cKWXKOc.,OWNK0o'.dNNX0x;.cKWXK000000000000XNWXl.,x0KNNd..l0KNWO;.:OKXWK; .kWx. ;O00000000000000000000000XWX: .xWk. ;KW    //
//     .dWO' ,KNo  oW0, '0Wd. cNXc.,xKXNNd..o0XNWO,.:OKXWXc.,xKXNNd.............oXNWXKk,.:KWNK0c.,kWNXKo..oNK; .kWx.  ........................lNX: .xWk. ;KW    //
//     .dWO' ,KNo  oW0, '0Wd. lNK; .kW0l:cod0WXd:codONNk::loxXW0l:coddoodoodoodol::cOWXkol::xNNOdoc:oKWd. lNK; .kWKxoddoooddddoddddddddddod:  :XX: .xWk. ;KW    //
//     .dWO' ,KNo  oW0, 'OWd. lNK; .kWx. :XWWW0, '0WKkxc,:OWNOxo;;dNWWWWWWWWWWWNx:;;lxOXW0:,cdkKWK, 'OWd. lNK; .cxxxxxxxxxxxxxxxxxxxxxxxOXWx. :XX: .xWk. ;KW    //
//     .dWO' ,KNo  oW0, 'OWd. lNK; .kWx. :XWNXO; ,0Wd. lXNNXO,.;0NWWWWWWWWWWWWWWWNNK:.'kXNNNo..oN0, 'OWd. lNX:  ......................  .kWx. :XX: .xWk. ;KW    //
//     .dWO' ,KNo  oW0, 'OWd. lNK; .kWx. :XNo',oO0NWd. lNXl';dO0NWWWWWWWWWWWWWWWWWWNKOd;.cKNo  oN0, 'OWd. lNNKOOOOOOOOOOOOOOOOOOOOOOOx' .kWx. :XX: .xWk. ;KW    //
//     .dWO' ,KNo  oW0, 'OWd. lNK; .kWx. :XX: .xWKdllclOWK; .;lxXWWWWWWWWWKdlllllllo0W0' ,0Wo  oN0, 'OWd. 'clllllllllllllllllllllloOWK; .kWx. :XX: .xWk. ;KW    //
//     .dWO' ,KNo  oW0, 'OWd. lNK; .kWx. :XX: .xWk. ;KWX0x'  ..;x0KWWWWNK0o.  .....'o0d. ,0No  oWK, 'OWk,........................  lNK; .kWx. :XX: .xWk. ;KW    //
//     .dWO' ,KNo  oW0, 'OWd. lNK; .kWx. :XX: .xWk. ;XNo.   .xXd..cXWWWK;.   ,OXXXX0:.   ,KNo  oNK, 'OWNKKKKKKKKKKKKKKKKKKKKKKXKl. lNK; .kWx. :XX: .xWk. ;KW    //
//     .dWO' ,KNo  oW0, 'OWd. lNK; .kWx. :XX: .xWk. ;KNl    .kWx. .,:kWK,    ;KWWWWX;    ,0No  oW0, 'OWOc;;;;;;;;;;;;;;;;;;;;oKWd. lNK; .kWx. :XX: .xWk. ;KW    //
//     .dWO' ,KNo  oW0, 'OWd. lNK; .kWx. :XX: .xWk. ;KNx:,. .cd:  .,:kWXo;'  .odddddc;'  ,0No  oW0, .cdl:;;;;;;;;;;;;;;;;;,. '0Wd. lNK; .kWx. :XX: .xWk. ;KW    //
//     .dWO' ,KNo  oW0, 'OWd. lNK; .kWx. :XX: .xWO,.:0XNWK;   .   ;0XNWWWWO, .......xNO' ,0No  oN0,   .cKWXKKKKKKKKKKKKKNW0, 'OWd. lNX; .kWx. :XX: .xWk. ;KW    //
//     .dWO' ,KNo  oW0, 'OWd. lNK; .kWx. :XX: .xWN0Oo''dNK; .o0l.  .'xNWWWN0OOOOOOO0XWO' ,0No  oN0, .d0KNNd............'xW0, 'OWd. lNX; .kWx. :XX: .xWk. ;KW    //
//     .dWO' ,KNo  oW0, 'OWd. lNK; .kWx. :XNkllccdXWd. lNK; .kWKdlllo0WWWWWWWWWWWWWWWWO' ,0No  oNXxlxXW0oclllllllllll'  oW0, 'OWd. lNX; .kWx. :XX: .xWk. ;KW    //
//     .dWO' ,KNo  oW0, 'OWd. lNK; .kWO;'ckOXWK, 'OWd. lNK; .oOOOOOOOOOOOOOOOKNWWWWWWWO' ,KNo  :k0XWN0ko,'dNNKOOOO0NNo  oN0, '0Wd. lNX; .kWx. :XX: .xWk. ;KW    //
//     .dWO' ,KNo  oWK, 'OWd. lNX: .kNNXXo..dNK, 'OWd. cNK;   ...............cXWWWWWWWO' ,KWo.  .'kNO,.:0XNNK:..  ;KNo  oW0, 'OWd. lNX; .kWx. :XX: .xWk. ;KW    //
//     .dWO' ,KNo  oWK, 'OWd. lNN0xd:,oXNo  oNK, 'OWd. lNK; .cxxxxxxxxxxxxxxx0NWWWWWWWO' ,KWKkxxxd:,:ox0NNx;;lxl. ,0Wo  oW0, 'OWd. lNX; .kWx. :XX: .xWk. ;KW    //
//     .dWO' ,KNo  oW0, 'OWOc:loxKWO' ,KWo  oWK, 'OWd. lNK; .kWWWWWWWWWWWWXxdONW0ddxKW0' .cdodoodoc:oKWKxol:cOWO' ,0No  oW0, 'OWd. lNX; .kWx. :XX: .xWk. ;KW    //
//     .dWO' ,0No  oWK:.,kKXNNl .dWO' ,KWo  oNK, 'OWd. lNK; .kWWWWWWWWWWWWk. ;KNl. .dW0'  .......'dKKKKo..oNWXKk,.:KNo  oWK, 'OWd. lNK; .kWx. :XX: .xWk. ;KW    //
//     .dWO' ,0No  oNNK0x,.cXNl .dWO' ,KWo  oNK, 'OWd. lNX; .kWWWWWWWWWWWWk. ;XNc  .dWO' 'x000000k;....:kKXWXc.,x0KNNo  oN0, '0Wd. lNK; .kWx. :XX: .xWk. ;KW    //
//     .dW0' ,0W0dlc:l0Wk. ;XNl .dWO' ,KWo  oNK, 'OWd. lNX; .kWWWWWWWWWWWWk. ;XNc. .dWXxokXWOc:cc;. .:okNNkc;. .kW0lccld0W0, 'OWd. lNK; .kWx. :XX: .xWk. ;KW    //
//     .dWKc':dkKWX: .xWk. ;KNl .dWO' ,KWo  oNK, 'OWd. lNX; .kWWWWWWWWWN0ko;'oXNx;,,okOXWWWNx,'''''':dk0NNx,'. .kWx. :XWKkd:'cKWd. lNK; .kWx. :XX: .xWk. ;KW    //
//     .dXNNNx. cXX: .xWk. ;KNl .dWO' ,KWo  oNK, 'OWd. lNX: .kNNWWWWWWWK; 'kXXWWNXXO; 'OWWWWNNNNNNNNk'.:KNXXO; 'OWx. :XXc .xNNNNd..lNK; .kWx. :XX: .xWk. ;KW    //
//    kxc'c0Wx. :XX: .xWk. ;KNl .dWO' ,KWo  oWK, 'OWd. lNN0kd:'lXWWWWWW0,  .'oXNx;,.  .kWWWWWWWWWWWWXOko,''',okOXWx. :XX: .xW0:'cxkKWK; .kWx. :XX: .xWk. ;KW    //
//    WX; .kWx. :XX: .xWk. ;KNl .dWO' ,KWo  oWK, 'OW0lclod0WO' ,0WWWWWWXdc,  .cl'   ':oKWWWWWWWWWWWWWWWd. .:l0WXxolcckNX: .xWk. ;KWOolc:oKWx. :XX: .xWk. ;KW    //
//    WK; .kWx. :XX: .xWk. ;KNl .dWO' ,KWo  oWK:.;x0XWNl .dW0:.;k0XWWWWWWWO;.......'xWWWWWWWWWWWWWWWWWWd. cNWX0x;.cKWXKOc.,kWk. ;XNl .dWNK0d'.lNX: .xWk. ;KW    //
//    WK; .kWx. :XX: .xWk. ;KNl .dWO' ,0Wo  oNNXKx,.cXNl .dNNXKd'.lXWWWWWWNXKKKKKKKKNWWWWWWWWWWWWWWWWWNd. lNXc.,xKXNNd..o0KNWk. ;KNl .dW0;.;kKXWX: .xWk. ;KW    //
//    WK; .kWx. :XX: .xWk. ;KNl .dWO' ,0W0doc:l0Wk. ;KW0doc:lKWx. :XWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWKl:cod0WK; .kW0l:cod0WXd:codONNl .dW0' ,0WOc:loxKWk. ;KW    //
//    WK; .kWx. :XX: .xWk. ;KNl .dWKl,:dx0WX: .xW0c,cdkKWX; .kWO:,cdxxxxxxxxxxxxxxxkKWWWWWWWKkxxxxxxo:,oXWKxdc,c0Wx. :XW0kd:,lKWKkxl;:OWO' ,KWo  oNNOxo:,oXW    //
//    WK; .kWx. :XX: .xWk. ;KNl..dXNNNx. cXX: .xWWNNd. lNX: 'kXXNNo.  ..    ........dXNNWNNXo.......;ONNXKl..xNNNXx..cXXc .xNNNXd..oXNNXk, ;KWo  oWK, 'ONNXX    //
//    WK; .kWx. :XX: .xWk. ;XWKOx:.:0Wx. :XX: .xWWWWd. lNNKOx;.cKNo  :kd. .oOOOOOOOx:.:0WO;'ckOOOOOO0NWk,'ckOXWKc.:xOKWX: .xW0:':xOKWXl';dO0NWo  oW0, 'OWk,.    //
//    WK; .kWx. :XX: .xWKdccloONK; .kWx. :XX: .xWKdllclONNkllccxXNo  oW0, 'OWWWWWWWK; .kWx. :XNkllllllllclONNkllccxXW0ollco0Wk. ;XWOolccdKWKdllclOW0, 'OWd.     //
//    WK; .kWx. :XNo.,dOKNWd. lNK; .kWx. :XX: .xWk. ;KWX0k:.;0WN0O:  oW0, 'OWWWWX00x' .kWx. :XX:  .....lXWX0k:.;0WN0Ol''xWNK0d,.lXNl .dWNKOd,.oNWK0k;.:KWd.     //
//    WK; .kWx. :XWXXO;.;0Wd. lNX; .kWx. :XX: .xWk. ;KNo..oKXNWk'.   oW0, 'OWWWXo...  .kWx. :XX: .dXXKKXNNo..dKXNWk'.c0XNWK:.,kXXNXl .dW0;.;OXXNXl.'xXXNNd.     //
//    WK; .kWXkdl;:kWK, 'OWd. lNK; .kWx. :XX: .xWk. ;KNl .dWKl;codddxKWK, 'OWO:;ldddddkXWx. :XX: .xW0l;;;;ldxKWKo;cox0NNx;:ldkXWO:;ldxKW0' ,KWk:;ldkXWKl;cdd    //
//    WXd;:odONNo  oW0, 'OWd. lNK; .kWx. :XX: .xWk. ;KNl .dWKl;coddddddoc;lKWOc;lddxdddddo:;xNX: .xWk. .,:xNNOxo:;oXWKxdc;c0WXkdl::xWNOxo:;oXNo  oWNOdo:;dXW    //
//    XXNWO' ,KNo  oNK, 'OWd. lNK; .kWx. :XX: .xWk. ;KNo..dKXNNk'......'kNNXXXNNo........:KWNX0c.'kWk. ;KNNX0:.,OWNXKo..dNNXXk,.cKWNX0:.,OWNXKo..dWK, 'OWNXX    //
//    .,kWO' ,KNo  oN0, 'OWd. lNK; .kWx. :XX: .xWk. ;KWX0k:.;0WX0O0OO0O0NW0;.lXWX0000000OKNWx''lO0XWO. ;KNd''oO0NWO,.ck0XWKc.;x0KWNd''oO0NWO;.ck0XWK, 'OWk,.    //
//     .dWO' ,KWo  oN0, 'OWd. lNK; .kWx. :XX: .xWKdllclONNkllcccccccccccccclllccccccccccccccllo0WXxclllkNNl .dWXdccllkNNklcllxXW0ocllo0WXdclllkNNkllllxXWd.     //
//     .dWO' ,KNo  oW0, 'OWd. lNK; .kWx. :XNo',oO0NWk,'lkOXWKc............cKWk,............'oNWKOx:.cKWXOkl',kWO' ,KWXOkc';OWN0Oo,'dNNKOd;.lKWXOkc';OWN0Oo,'    //
//     .dWO' ,KNo  oW0, 'OWd. lNK; .kWx. :KNNXO;.;0NNXKl..xNNXKKKKKKKKXXKKXNNXXKKKXKKXKXKKKKXNXc.'xXNNNx..lKXNNO' ,KWd..oXNNNO,.:0XNNK:.'kXNNNo..oXNNNO,.:0X    //
//     .dWO' ,KNo  oW0, 'OWd. lNK; .kWXkxl;;kWNOxo:,oXWKkdc,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;lxkXW0c,cdkKWXo,:oxONWo  oNXo,:dx0NNx;;lxOXW0c,cdkKWXo,:dx0NW    //
//     .dWO' ,0No  oWK, 'OWd. lNNd:clokNWOc:loxKWKl:cod0WNd:::::::::::::::::::::::::::::::::::cOWNkdoc:dXW0doc:lKWKxol:cOW0, '0WKxol:cOWXkolc:xNNOdoc:oKWKxo    //
//     .dWO' ,KNo  oNK, 'OWx'.l0KNW0;.;OKXWXl.'dKXNWx'.l0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKk;.;0WNK0l.'xWNXKd'.lXWXKk;.;0Wd. lNNXKk,.:KWNK0c.,kWNXKo..    //
//     .dWO' ,KNo  oNK, 'OWXKOl.'kWNK0d'.oXWXKk;.:0WNKOl.........................................'d0KNWk'.lOKNW0:.;kKXWNo.'d0KNWd. lNXc.,x0KNNx'.l0KNWO;.:O0    //
//     .dWO' ,KNo  oNNkolccxNWOolc:oKWKdolccOWXkolccxNWOooooooooooooooooooooooooooooooooooooooooodKWKoccooOWNxcclokXWOlclodKWKo:cloOWK; .kW0oclod0WXdcclokNW    //
//     .dWO' ,KWk;,lkOXW0:'cxkKWXo';dk0NWk;,lkOXW0:'cxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkd;'oXWKkxc'c0WXOkl,;kWN0kd;'oXWKkxc'c0Wx. :XWKkd:'cKWXOk    //
//     .dW0, ,0NNNKc.'xNNNNd..lXNNNO,.;0NNNKc.'xNNNNd...............................................,ONNNXl..dNNNNx'.cKNNN0;.,ONNNXl..dNNNNx. cXXc .xNNNXd..    //
//     .dWN0ko;,dNWKkd:'cKWXOxl,;kWN0ko;,dNWKkd:'cKWXOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk0NWk;,lxOXWKc':dkKWNd,;ok0NWk;,lxOXWKc':dkKWX: .xW0c'cxk    //
//    ccloxKW0lccod0WXdcclokNNkccloxKW0l:lod0WXdccloooooooooooooooooooooooooooooooooooooooooooooooooooolcckNNkolccdXW0dol:l0WKxolcckNNkolccdXW0dolcl0Wk. ;KW    //
//    WXc.,x0KNWx..l0KNWO;.:OKXWXc.,x0KNNx'.l0KNWO;....................................................lXWXKO:.;OWNK0l.'xNNK0x,.cXWXKO:.;OWNK0l.'dNNK0x,.cXW    //
//    WNXKk,.:KWNK0c.'kWNXKo..oNNXKk,.:KWXK0c.'kWNKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXWNo..oKKNWk'.c0KNWK:.,kKXNNo..oKXNWk'.c0KXWK:.,kKXNW    //
//    :cOWXkol::xNNOdoc:oKWKxol:cOWXkol::xNNOdoc::::::::::::::::::::::::::::::::::::::::::::::::::::::::::loxKWKo:codONNx::ldkXWOc:loxKWKo:codONNx::lokXWOc:    //
//     .dWWWWx. :XWWWK, '0WWWNl .dWWWWx. :XWWWK,                                                          lNWWW0' ,KWWWX: .xWWWWd. lNWWW0' ,KWWWX: .xWWWWd.     //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CDBLL is ERC721Creator {
    constructor() ERC721Creator("CDB: LOST LEGENDS", "CDBLL") {}
}