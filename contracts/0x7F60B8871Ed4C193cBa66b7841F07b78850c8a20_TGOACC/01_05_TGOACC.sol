// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TGOA: Community Curated
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    XXXXXXXXXXXXx':KNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0oxXXXXXXXXXXXXXXXXXXXdcOXXXXXXXXXXXXdcOXXXXN    //
//    XXXXXXXKkoc;. .:ldk0XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0oxXXXXXXXXXXXXXXXXXXXkcxXXXXXXXXXXXKllKXXXXN    //
//    XXXXX0o,.         .,dKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKK0OOOO000OkkkO00KXXXXXXXXXXXXXXXXXXXXXKxoKXXXXXXXXXXXXXXXXXX0cdXXXXXXXXXXXk:dXXXXXX    //
//    XXXXx'..',,..,;'','..;kXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKOkdolc:;;;;;;;;,,,,;:cldk0KXXXXXXXXXXXXXXXXXOoOXXXXXXXXXXXXXXXXXNKooKNXXXXXXXXXdcOXXXXXX    //
//    XXXd..::;:clc;cllccl, ,kXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0Oxoc;,,,,,,,,'','''''''''''',;cox0KXXXXXXXXXXXXXKdxXXXXXXXXXXXXXNXXNXXxl0NXXXXXXXXKll0XXXXXX    //
//    XN0, .okxookkkkoldOO:  cXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKOxl:,,,'''''''''''''''''....'''''''',;cdkKXXXXXXXXXXXko0NXXXXNNNNNNNNNNNNNklONXXXXXXXXOcdXXXXXXN    //
//    XNk. .llcldlckd;:xo;.  ;KXXXXXXXXXXXXXXXXXXXXXXXXXX0xc;'''''''''''........................'''',:oOXXXXXXXXXKxxXNNNNNNNNNNNNNNNNN0okXNXXXXXXXdckXXXXXXN    //
//    XX0, .cc::lc',,'lo:'.  cXXXXXXXXXXXXXXXXXXXXXXXXKxl,..........................................''',lkKXXXXXXN0d0NNNNNNNNNNNNNNNNNKoxXNXXXXXXKllKNXXXXXN    //
//    XXXd. .,;,,;,;';;,:'. ,OXXXXXXXXXXXXXXXXXXXXXXKkc................................................'',lOXXXXXNXkkXNNNNNNNNNNNNNNNNXdxXNXXXXXXkcxXXXXXXXN    //
//    XXXXx' .,',',,.,'',..;OXXXXXXXXXXXXXXXXXXXXXXOl'.......................             ................';dKNXXNN0k0NNNNNNNNNNNNNNNNXxdKNXNNXNKol0NXXXXXXN    //
//    XXXXX0o'.         ..lKXXXXXXXXXXXXXXXXXXXXXKd;.......................                 ................,l0XXNNXkkXNNNNNNNNNNNNNNNNkdKNXNNXNOcdXNXXXXXXN    //
//    KXXXXXXKkoc;..':ldxokXXXXXXXXXXXXXXXXXNNXN0l'......................                    ...............''cOXNNN0k0NNNNNNNNNNNNNNNNkdKNXNNXXdc0XNNXXNXXN    //
//    kXXXXXXXXXNXl'dXXN0okXXXXXXXXXXXXXXXNNNXXOc'......................                     ................'':xXNNXkONNNNNNNNNNNNNNNNkdKNXNNN0ldXNXXXNNXXN    //
//    c0NXXXXXXXXXl'dXXX0okXXXXXXXXXXXXXXNNNXN0c'.....................                       .................',;xXNN0kKNNNNNNNNNNNNNNNxdKNXNNNkckNXXXXNNNNN    //
//    co0XXXXXXXXXo'dXXX0okXXXXXXXXXXXXNNXXXX0l,....................                          .................',:kXNKk0NNNNNNNNNNNNNNXxdKNNNNKooKNXXNNNNNNN    //
//    OcoKXXXXXXXXo'oXXX0okXXXXXXXXXXXXXXXXNKo,....................                           ................''',:kNXOOXNNNNNNNNNNNNNXxdKNNNNOlxXNNXXNNNNNN    //
//    XkcxXXXXXXXXd'oXXX0dkXXXXXXXXXXXXXXXXXx;'......................                         .................''',c0N0kKNNNNNNNNNNNNNXddXNXNXxlONXNXNNNNNNN    //
//    XXdckXXXXXXXd'oXXXKdkXXXXXXXXXXXXXXXN0:'........................        .              ....................'',oXXkONNNNNNNNNNNNNKodXNXN0ldXNXNNNNNNNNN    //
//    NNKdcOXXXXXXx,lKNXKxxXXXXXXXXXXXXXXXXd,'.......................     ..........        ......................'':ONkkXNNNNNNNNNNNNKoxXNNXxl0NNNNNNNNNNNN    //
//    XXNKolOXXXXNk,cKNNXxdKXXXXXXXXXXXXXXO:'.......................   ...........................................'',dXOx0NNNNNNNNNNNN0lxNNN0lxXNNNNNNNNNNNN    //
//    XXNNKolOXXXNO;cKNXNOd0NXXXXXXXXXXXXKo'.......................   .............................................''cKKxONNNNNNNNNNNNOlkNNXdo0NNNNNNNNNNNNN    //
//    XNNXNKdcOXXN0::0NXN0dkXXXXXXXXXXXXXx,........................   .........   .................................'';OXxkXNNNNNNNNNNNklONNOoONNNNNNNNNNNNNN    //
//    KNXNNNXxlkXNKc;ONNXXkxKNXXXXXXXXXNO:'........................   .......... ..................................'',xXOxKNNNNNNNNNNXxo0NKdkXNNNNNNNNNNNNNN    //
//    lx0XNXXXklxXXo,dXNXN0dONXXXXXXXXNKo,.........................................................................'''oX0x0NXXNNNNNNNXddXXxxXNNNNNNNNNNNNNNN    //
//    c::okKXNXOodKk;lXNXNXkxKNXXXXXXXXk:''.........................................................................''lKKx0NXNNNNNNNN0dkXxd0NNNNNNNNNNNNKOxx    //
//    Kkoc:cdOKX0dox::0NXXN0xOXXXXXXKKKo::'........................'.............'...''.....''......................''c0KkONNNNNNNNNNOd0kd0NNNNNNNNNXKOdolld    //
//    NNX0xo::lxOKkl;;xXXNNXOxKNXXXXXKxlxl'.......................';,'...............'......;;;.....................'':0XkOXNNNNNNNNXxdxdOXK0Okkxkkkdlccllcl    //
//    NNNNNX0xlccoxko;lKNXNNKxkXXXXXX0ok0l''................;,....',,,.........''....'......;,;.....................'':0XOOXNNNNNNNN0occclllclc:::cldxxooddO    //
//    NNNNNNNNXOxl:lo:;dKNNNN0x0XXXXXkdK0l,'...............;dl,;,..''......''..',.. .,.....';;ll,....................':ONOkXNNNNNXOdl:ldxO00kxolodkKXNNNNNWW    //
//    NNNNNNNNNNNKkdlc:coOXNNXOxKNXN0xOX0l,................cxl,;;'':llc..'..''.;,...,;.....lllll:,...................':ONOOXNNNKkoc:lkXNX0xoloxOKNNNNNNNNNNW    //
//    NNNNNNNNNNNNNX0xlclld0XNXOkKNXkOXX0l,'..............':;..'.....'::,:;.,:::,..;l;.'.............................':OXO0XNN0occloxKKkdloxOKNNNNNNNNNNNNNW    //
//    NNNNNNNNNNNNNNNXd:cllokKXXOkK0kKNX0o,'..............lkd:;ooc:;;;cooxkxxkkkkxkOOkxdc::;;;:ll:,:ol'...............:0N00NNOllodoodxoodkKNNNNNNNNNNNNNNNNW    //
//    NNNNNNNNNNNNNNNKdc:cdoodx0XOkxONXX0o,..............'xKKOdoddddxk0OO0K0KKKKKKKKKKKOkOOxdooooldO00l...............c0N0KN0ocxOxooodk0XNNNNNNNNNNNNNNNNNWW    //
//    NNNNNNNNNNNNNNNKdxdcodooodx0xo0NNX0o,..............;OXKKK000000KKKKKKKKKKKKKKKKKKKXKKK000O00KKKKx,.............,l0X0KNklokkddxOXNNNNNNNNNNNNNNNNNNNWWW    //
//    NNNNNNNNNNNNNNN0dkKocddoxxddllk0XXKd,...........  .lKXKKKXKXXKKKXXKKXKKKKKXXKKKXXXXKXXKXXKKXKXKXO:...........',:lOX0XKdlddddx0NNNNNNNNNNNNNNNNNNNNWWWW    //
//    NNNNNNNNNNNNNNNOdON0llxdd00xllxk0KXx,...........  .oKXXKXXKXXXXXXXXKXXXKXXXXXKKXXXXXXXXXXXXXXXXXKc.........',;;;ckK0X0xxxOOdxKNNNNNNNNNNNNNNNNNNWNWWNX    //
//    KKXNNNNNNNNNNNXxdKNNOlokddKKdoxxxOKk;...........  .oKXXXXXXXXXXXXXXXXXXXNNNNXXXXXXXXXXXXXXXXXXXXKc........';;;;;:dOOOkxdOXOdx0NNNNNNNNNNNNNNNNWWWNXKO0    //
//    XXXNNNNNNNNNNNKdkNNNXkldOxxOxOKkxxkd;..........   .lKKXXXXXXXXXXXXXXXXXXNNNNNXXXXXXXXXXXXXXXXXXX0;......',;;;;,,;lkkkxodKKkkxONNNNNNNNNNNNNNWWNXK0OKXN    //
//    NNNNNNNNNNNNNXkdKNNNNXklx0xdoONX0kxo,...........   'kXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXo. ...',;;;;,,,',:xOkdokKOOKkkXNNNNNNNNNNNWNNK000XNWKx    //
//    NNNNNNNNNNNNNKdkNNNNNNXxlk0kodKNNKOo,...........  ..:0XXXXXXXXXXXXXXXXKOOKKK00KXXXXXXXXXXXXXXXXk;. ..,;;;;,,,''..;xKOdd00kKN0xKNNNNNNNNNNNX0O0XNWWNOcl    //
//    NNNNNNNNNNNNXxdKNNNNNNNXxokKOod0XNXd,..........  ....lKXXNXXNXXXXXNXXNXXXKKKXXXXNXXNNNNXXXNNXX0c....,;;;;,,,'....,kKxdO0O0NNKk0NNNNNNNNXK00KNNWWNXx:oK    //
//    NNNNNNNNNNNXxd0NNNNNNNNNXxokX0dokKXd'..........  ....'lKXXNXNNXNXXNNNNNNXXXNNNXXXNNNXNNNNNXXNKl...',,;;;;,''.....,dkdkKO0XNNXOOXNNWNXK00KXNWNNWXkcckXW    //
//    NNNNNNNNNNKxd0NNNNNNNNNNNXkokXKkoxkl'.......... . .....cOXXNNXNNNNNXXXK00KK000KXXNNNXNNNXXNN0c'',,,,,,,,,'.......'cdkK0OXNNNNKk0NNX00KXNNNNNNKkc:dKNWW    //
//    NNNNNNNNXOdxKNNNNNNNNNNNNNKkoxO0xoo:'.......... ........,dKXXNNNNNXK00OkkkOOOO0KKXXNNNNNNNXx:',;;,,,,,'.'.......'';xK00XNNNNNN0k000KNWNNNXKOdcco0NWWNW    //
//    0XXK0OkxdxOXNNNNNNNNXXK0OkOOkxdkKKd,''....................:kXNNNNNXNNXXKKKKKKKXXNNNNNNNNXOl,,;;:;,,,'...........'':k0OXNNNNNNX0kkKNNNNXK0kdccd0NNNWWNW    //
//    ;:c::ldOKNNNNNNNXK0OkkOO0XXXNXOxkKx,,'....................',;dKXNNXNNNXXXXXXXXXNNNXXNNKkxl,,;;::;,''...........''.;okKNNNNXK0KXKOkKKK0OxdookKNNNNNWNNW    //
//    oc:,,,:codkO00Okxxk0KXNNNNNNNNXKOx:,,......... ...........':..cx0XNNXNNNNNNNNNNXXXXX0kllxc,;:;;;;'..............''':xKNXXK0KXXKK0kxkkdoox0XNNNNNNNWNNW    //
//    NXKOkdoc:;,;;::cok0KKKKKXXXKKKKKKd,''......................:c',:cod0XXXNXXXNNXNNX0kdolcxx:;:c:,,'.... ....'..''.'''':xOOO0KKKK00Oxollx0XNNNNNWNNNNXK00    //
//    XNNNXXK0Okxxdolc::::cllooddxkOO0Ol''.......................'o:,cc:'':dOKKXXXXKOd:;ldxooOl;lcc:,'..............''..'''ckOkO0OOkxddkO0OOKNNNNNNNXKOkxxdk    //
//    kO0OkO0KXNNNNNXK0Okxdoolllllodxkxc'....................''...:o,cxdc. ..',;;;,'...lk0xlkd;;::c;'.''.............'...,';oxkkxkO0KXXNNNX0kkO0OOkxoc::::;c    //
//    KKK0OOOOOOOOOOOO00000Okkxoolooolc,...................''''''..ll;dOkc.    .  ....cOK0odk;.;:;:c;''...............'..'',cdOOkk00OOOOkxxdlcc:::::cclodxxO    //
//    NNNNNNNNXXK00Okkxddddoooooooodooc,..'.............'''''',;,. ;o;lkOd'         .,kKKkoxo..;:c::c:;,'.... ....'...''..',:codxxdoodddoddxxxkkkO0KKXXNNWNN    //
//    KK0OOkkxxddoollllllooddxxkkkkxol:''''...';.......,,,,,,,,'.  .cl:d0O:   .......c0XOdxd'...,:::::cc:,... .........''.'';clkKK0K000OkkkO0KXNNNNNNNNNNNNN    //
//    lllccccloodxxkkOO00KKKXXXK0kdloo,.''....,,......'',;;;;,,..   'oc:kKo.    ....'dX0ddk;.. .';:cccll:,...  ........'''.',lllOKXNNNNNXXK0OkkkO0KXNNNNNNNN    //
//    l:;:d00KKXXNNNNNNNNXXK0Oxdolloko'',''''.........',;;;;,'...... ;d;c0k' .....'.;kXdckl......',:clllc;,......',......''.':dockKK0KKKKKKXXXK0OkxxkO0KXNNX    //
//    ;cd0XNNXXNNNXK0kxxddoolloddooxd;','''''...'...',,,;;,'.........'od;d0;.''''','c0k:xx;'........,cool::ccc,...''.....''..,lkdo0XXKKK0000000000Okxxxxxxdo    //
//    OKXXNNXKOkdoolodddlcclxOKXK0KXx;',''.....''..,;:::;;;;,,,'....'';ko:ko,:;,,,:;oOclOl,,'.',;cclooooddooll:. .........'..'cxkdokXNNNNNNNNNNNXXXXXK0xloxk    //
//    NNX0xdlllodk0KKOxocok0XXXX0OOkl,,,''....''..'':c,;;;;,..'',;;;;,'oOlokdoooolooko:0x;;clllc::,;clllc:;;,;;...............;xKkdox0XXNNNNNNNNNX0kxddx0XNN    //
//    kolcldk0XNNXKOdcldOKXXX0OkkO0Oc','',,...'....,:c,,,;;,........,:;c0d:ddxkxxxdoo;lKdcc:,......'col:',,,''''...........'...dXXOdddxO00KXK0OkxddxkKXNNNNN    //
//    ldOKNXXXXXKkocld0XXK0kkkOKXXXx,','';;..'..;;..,;;,,,,;::,'..',,,;:xo:c;lxxxxc;:,lOo:,''..'':ldlc:,,,,'.';;,......,'......:k0OdddoddodxdodkOKXNNNNNNNNN    //
//    XNXXXXXXKkoclx0XKOkxkOKXXXXX0l'''.':,..'..,;'..,,,,,,;;:::;',;,,;,co:''cdoodc'.,lxxl'...'cloo:,::,''''',;,,'.....';......,dOOkddoclk0KK0OO0KXNNXXNNXXN    //
//    NXXXXKkol:lx0X0xxkOKXXXXXXXXO;.'..;c'....',,,,'',,,;:;;:c::;,:cc:,;;,.'okdxkd,.',:oolc;,;cldl,',,,,;;,,,,,,,'.....:;......xXXXkoddodOKNXXK0OOOKXNXXXNN    //
//    XXXXKo;:cd0KOxxOKXXXXXXXXXXXd'....::.....,,,;;;;,',;:::;;c:,;:loccc:'..,lloo:..';c:cc:,',;oo;'',::clc:;,,,,,,'....,:......lXXXKxoxxddkKXNXXXKOkk0XXNXN    //
//    XXXXx:;oO0kdxOXXXXXXXXXXXXXKl.....;,.....,;;;::c::::::;;,clc:;cdl:loc:;:lllolc::llcl:,';cll::;,;cclcco:,;;,,,;,....;,.....cKXXXKxokOxdx0XXXXXXX0kkOKXN    //
//    XXOo:,lOxdx0XXXXXXXXXXXXXXX0:.....'.....';;;:lollllcolloccccc::od:::codxkkkxxdllolxx;.,llc;:c;,:clo:cxl,;;;;,;l;....'.....:0XXXX0doOOxddOXXXXXXXXKkxOK    //
//    0xc:c;cdkKXXXXXXXXXXXXXXXXXO, .........':::::loodddclxddl::clc:loc::::;':coxdc;:::::;;:cc:;cc;;ccod:oOo;:;;;;:dl'.........'kXXXXXOoo00xodk0XXXXXXXXKOk    //
//    l:coccxKXXXXXXXXXXXXXXXXXXXd. .........;o::c:codxxkdlxxooc::c:cclc:::::'';ldlcdo::clc::cc:;cc::ccdo:x0o:::;:;cxxc..........oKXXXXXOooO0kdodOKXXXXXXXXX    //
//    ;;:co0XXXXXXXXXXKXXXXXXXXXKl'. ........:xc:cccldkO0Oookdolccc::cloccclddoooooooc:cdkoc:::::clclcoxlcO0l::::::okOx'........':OXXXXXX0dlx0Odoox0XXXXXXXX    //
//    ::;:oddddxKXX0xddddddddx0Xx',c:::::::;.;kdclcllloooddldxolcllcclllcc:ldoddooolc:clk0dcccclllllclxklcodlccccccdO0xc::::::::o:c0Odddddo:cdO0kdoodkxddddd    //
//    ;c'......dKXO;.........oKOc':kKXXXXX0l.;xdll:;;,;..ckdll;;:cccllccllcoolodkxl'.,ldOOdlccclllllldOdc'.;:;coolokOl'lKKKKKKKddxcc,.......'lldOo;:cc:'...:    //
//    ldlcclclxKXKxlclllllclxK0::oloolllloc. ,ddoolollocok0kdlcoololllldololcclclllcllodxdlloollllooxOkdoc:oooolllx0koloodollll;cO0o;:lccllcoOklc;:oxollc;:k    //
//    xKXXXXXXXKKXXXXXXXXXXXXOlckXx:,.....:' .kXOx0K000OOOOOOOkOOkxdooodxxd;;cc,..:O0kkxddxkkkxxddxOkkkKK0O0XXOdldOKKXNd:c'...';ckXkloOXXXXXXXX0xlcoOOkxolco    //
//    KXXKKXKKXXXXXXXKKKKKKKK00KKXOc;'....cc..dX0k0KKKKK00K0KXK000Okkkkkxxkdllc,'':dkO0kxk0KKOkOOO0KKKKXXXXXXXKkk0KKXXXoco,...,:ckXXX0OKXXXXXXXXX0xlccoddolo    //
//    XKKKKKKKKKKKKKKKKKKKKKKKKKKKKxo:',..:kl,l0XOOKKKKKXKKKKKKKKKKKKK0OOOOxok0O0Kkdk0KK00KXXK0KKKKXXXXXXXXXXXK0KKXXXX0lxd'',,;od0XXXXXXXXXXXXXXXXXKOxolccco    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXOkOOdd0XOx0XK0KXXXXXXXXXXXXXXXXXXXXXXX0dONNNNOk0KXXXXXXXXXXXXXXXXXXXXXXXXKXXXNXXNXO0kclkxxKXXXXXNXXXXXXXXXXXXXXXXXXKK0K    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract TGOACC is ERC1155Creator {
    constructor() ERC1155Creator("TGOA: Community Curated", "TGOACC") {}
}