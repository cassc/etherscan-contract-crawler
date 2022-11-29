// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Strangers
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    :ccccllllllc:::;:::::::::::ccccccc:;,,,,,,::collcc:ccc:;;,''',;;lO0KXXXXXXXXXXXXXXKKK0OOkkc.l0kl. .c    //
//    :cllllllllllcc:::::::c::cccccccc::;;;:;,,:loc:;,,,;,;::cc:'',;,cO00XXXXXXXXXXXXXXK0K0Okkxk:,kX00d'      //
//    cccllllllllllc::;;;::::::::ccccc;;;;;;;;coo:;;;;;;,,,,',lo:,,;,dK0KKXXXXXXXXXXXXKK000kkdxo;dKXK0KOl.    //
//    llllllllolllllc::;;:cc::::cccccc:;;;::looc,,;;lddc;;,',,;cc;,,:k00KXXXXXXXKXXXXKK0000OOxxdxKXXXNXK0O    //
//    lllllllloolllcc:;;;::::;:::::::::;;:lodc;,,,,:ONN0xl;,,,,;cc;,oKKXXXXXXNXXXXXXXKK0000OOOOOKXXNXXXKKK    //
//    llolllllooolcc:;;;::::;;;;:::::;;;;:xd;;:;;;:c0NNKOd:;,,;,;c:,o0KXXXXXXNXXXXXXKXX00KK000KKXNNNXXXXKK    //
//    llollolooolc:::;;:::::;;::::::;,,;;lxc,:lxdcclONNKko:::lkx:;l;cKK0KXXNXXXXXXXXK0KKKXXKOk000KXXXXXKXX    //
//    lllloolool::;;;;:::::;;;;:::::;,,,:do;;cONXdcckNNKko:co0NNx;cc;OXKXKKXK0KKKXXXK0Oxdoc:,,cOK0KXXXXXNN    //
//    lolllllloc::;;;::::::,',;;::;;;;,:odc;;oKNNkccONN0dl:co0NN0c:l,cKXXK00Oxxxdllcc:;,',,,,,'d0O0XXXNNNN    //
//    lloolclll:::::::cc::;,'',,;:;;;;;cdl;;;l0NNkcckNNk::;:o0NNKo;c:,:cc::;;,,,'''',,,,',,,,,':OO0XKXNNNN    //
//    clooolloc;:::::cl:;;;,'',,,;;;:;cdl:;::cONNklcdXNx:,;:lONNXx;:l;'''',''''',,'''',,,,,,;,',xOOKKXNNNN    //
//    cldoooooc;::;:lll:;;;,'.'',,,::loc;;;:::kNNkccdXNkc,;ccxXNNO;;o:'''''''........'''''',,'''lO0KXNNNNN    //
//    :ldooool:;:;;clol:;;;,'.'',,,:cl:;;;;:::kNNx::dKXkl,,cckXNNk:;ll,.............''''....','.cOOKXNNNNN    //
//    :lollol:;::;;clcc:,,,,'.'''';lc;;;:c:;c:oXNkccd0XOx:,:lkKXXd,;lo:'...........'''''....',''l0KXNNNNNN    //
//    cloool:;;;;;:cc::;,,,,'..''';cl:,;oXO:::oXN0l:o0X0O:.;:okKKo';loc,....................',',dKKXXNNNNN    //
//    cllooc:;;;;;:::;;;,,;,'....',co:;;xN0:;:c0NKo:lxOkkc.,:lkO0d',:co;....................''.;k0KXXNNNNN    //
//    clllcc:;;;;::;;,,,,,,,...'..,co:;:xNK:,;:0NXo:lokkOo'':ok0Kd'',;oc'...................'..lO0XXXNNNNN    //
//    clllcc;,;;;;;;,,,,,,,'...'..,cl;;;dNXc';c0NNd:llxOOk,.:ckXXd..,':o;..................''.:kOOXXNNNNNN    //
//    cllccc:,,,,,,,,,,,',,'......,cc;,;oXNo,;l0NNo,ccxKKKc.c:xNXx.';'.,cc;,,,,,;;,,'.....',.,dOk0XNNNNNNN    //
//    clcccc:;,,,,,,,,,',,,'......'cl,,;c0Wx,,o0NNx'';dKKKo,,:ONN0;.,,...,,;;;;,,'',;;,...'''lkkkOKNNNNNNN    //
//    clllccc;,,,,,,'''','''.......co,.,;kXd..lKNNKx;,oKXXOloONNX0:..'.......',;:,',,::'..''lOxxOKXNNNNNNN    //
//    clllccc:,,,,,,'',,,'''.......:o,.';kXx,.cKXXXKOdkKXKkxOXXNXO: .;,'',:dk0Oo;'',;c;....ckkxkOKXNNNNNNN    //
//    cccllcc:;,,,,,,,,,,,,'.......:d;..,xN0xclOKKKK0000K0kkkO0KKk:..:;,cxKNXk;...',c:'.'',dOkkOO0XNNNNNNN    //
//    ccccccc:;,,,,,,',,,,,,......';l:...cXNXK000KXK0OOOkkkkxkkO0k:..::ckXN0:. .'.,:,.....:kOOO00KXNNNNNNN    //
//    ::::ccc:;;;,'''''''','.......'cl.. ,0NNNX0OkkOkdddodxxdxdxxdc..;xKXKo.  ...,:,.....'oO00O0KXXNNNNNNN    //
//    ;;;;;::;;;,,''.''..''''.......:o'. ,0NNNXOxdoddoooddxxxddxxo:.'xXN0c.  ...::'......;xkOkk0XNNNNNNNNN    //
//    ,;,,,;;;;;;,''.......''.......;o;. .kNNX0xolloo:;::coxxddxxl;,o00x;.  ...:c'.......lOOOkOXXXNNNNNNNN    //
//    ,,,'''',;;,,,''......''....''.;o:. .dNNXOolcclc,,,,;:lllodd:,:dxo,   ...::'.......'d0OOO0KNNNNNNNNNN    //
//    ,'.....',,,,,''...'...........;dc...cXNXx:;;,,,'';;:clllodocldxd,   ...,:'........,xO0000KXNNNNNNNNN    //
//    .......''',,''''..............,ol'. 'kNXkc,'......,;cloxkkkdxOk:   ....:;........ ;k0KK00KXXNNNNNNNN    //
//    .......'''''''''''''..........'ol;'  lXNO:........',lxkO0K0xxxl.  ....;:,.........;O0KKKKKXXNNNNNNNN    //
//    .......'''''''''''''..........'ll;,. 'ONKd;'......':odxkOOkdol'   .. .::,.........:OKXXXXXXXNNNNNNNN    //
//    .......''''.''''''''''''.......co;;. .lKKOl,. ...',;cloxkkxol,   ....,:;'.........:0XXXXXXXXNNNNNNNN    //
//    ......'''.....'''''''''''......;oc:.  .d00Oc.. .';:::cldxdol:.   ....;:'..........:0KXXNXXXNNNNNNNNN    //
//    ....'.''''..''...'''''''''......co:.   ,x0KOl;'.,:::ccclccc'.   ... .:;...........:OOKXNNNNNNNNNNNNN    //
//    ...''''''...'''..''''''''''.....,oc... .:ldO0xc;:ccc::::,'.     ....',............;0KKXXNNNNNNNNNNNN    //
//    ...''''''''''''''''...''''''.....:o;..  ...,;;;,,',,,....     .....','........... 'kKKXXXNNNNNNNNNNN    //
//    ....'''''''''''''''''''''''.......:l;... .         ...  .   .......,'.. ...........dNXNNNNNNNNNNNNNN    //
//    ....'.'..''''''''''''''''''..'.....,cl:......   ......'''''''....'...   ...........cXNXNNNNNNNNNNNNN    //
//    ....'.''..'''''''''''''''''''........,:::;::;;;;;:::ccc:;;;,,''''..     .......... .kNXNNNNNNNNNNNNN    //
//    .......'....'''''',''''''.......'.........',,,,,,,,,,;;;;;,,''..        .........   :KNNNNNNNNNNNNNN    //
//    .......'''..'.'''',''''''''................................           ............. .dNNNNXXNNNNNNNN    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract strgs is ERC721Creator {
    constructor() ERC721Creator("Strangers", "strgs") {}
}