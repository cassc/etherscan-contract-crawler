// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: COMIC
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    ....................;,.......;,............................................................;;.......,;.............':'....,;.....................;,...    //
//    ....................;,.......;,............................................................,;.......,;.............':'....;;.....................;,...    //
//    ....................;,.......;,............................................................;;.......,;.............':'....;;.....................;,...    //
//    .'''................;,.......:,............................................................;;.......,;.............':'....,;.....................;,...    //
//    '''''''..'..........;,.......:,............................................................;;.......,;.............';'....,;.....................;,...    //
//    ''''''''''''........;,.......:,............................................................;;.......,;.............';'....,;.....................;,...    //
//    '....',,',;'........;,.......;,............................................................;;.......,;.............';'....,;.....................;,...    //
//    '.....',;;;'.......';,.......;,................................................'...........;;.......;;.............';'....,;.....................;,...    //
//    ......'::''......',,;,......':,..............................................'cdxocllc;....;;.......;;''..,;.......';'....,;.....................;,...    //
//    .............''....';;......':,..........................................,:cldOKKK0Oxdkd:;,;;.......;;...'dd'......';'....,;.....................;,...    //
//    ...........'''''....;;......':,......................................',::coxddOKKK0xoldddkolo:......;;...cKO;......';'....,;.....................;,...    //
//    .........',;;;'..',;:,......':,..................................',,;:cccloxO0O000OOOkxxxk00kl'.....,;..'xWXc......';'....,;.....................;,...    //
//    .......,::;;;cc;',coc'......':,..............................',:cc:;:ldxkOOOOOkkkkkOOOO0KKXK0kdl:'..:c;;oXWNx,.....,;'....;;.....................;,...    //
//    ......';cc;coddo;'';:,......';,...........................';:ll;,,;lx0KK0OOOOkkkOO000OOO0KXK000KKOkO0KXXNWWWNKOkdl:c:'....;;.....................;,...    //
//    .......';c:oOOxoc;,,:,......':,........................';:ll:,'.';dO00KX0kkkkkk0K000OxxxxkOkkkOKKXXXKKKKNWMWKOkxxdccc'....,;....................';,...    //
//    ........;clx0XKkooxdl,......':,......................':ooc:,....'lkkkk0X0xddddxkO000OkxxxxxxxxkO000KK0OOKWW0:......,;'....,;....................';,...    //
//    .......';cx0NNXKO0Kkl'......':,.....................;lxxo:......;dOOOxkOkxdddooooxk0KKK0OkOOxxkO0OOO0KK0OXNd.......,;'....,;....................';'...    //
//    ........,:o0XNNXKKd::,......':,...................,cooooc.. ....,dkOkxxxO00OOOxoodxOKKK0OkkOO00KK000KK0koO0:.......,;'....,;....................';'...    //
//    .........:kXNNNNXO:,:'......':,...............'..cxkdoxd,.   ...'lxxxxxOKK000kdooxkxkOkkxkO0KKK0000OOOOkodo;:;.....,;'....,,....................';'...    //
//    .',:lodxxOKXXXNXKOxxxc......':'................'lKXKOO0c..',.....:dxxdxOKKOkkkddxxxdddddxkk0XKK0OOkkxkO0ko:,:,.....,;'....,,....................';'...    //
//    .,:kNNNWWWWWNNWWWWNNXO;.....':'................l0NXKKKl..'ldc....:xkOkkOKK0OkxxxOOxxxxdddxO0K00OkxxkkkOKKd,','.....,;'....,,....................';'...    //
//    ..,xNNNNNNWWWWNNNNNXXO:.....':'..............',ckKXXXx'...,;.. ..;dO0OO0KKOxdxOKKKOkxxxkxkKKK0kkOOOkO0KXKkc,','....,;'....,,....................';'...    //
//     .,xNNNNNWWWWWWWNNNXXO:.....':;,''...........';cok00kc...      ..,lk00OOOkxdox0K0KKOxkO0000OOOOOO0000XNWWXx:,;,....,;.....,,....................';'...    //
//    ..'xNNNWWWWWWWWWWWNXXO:.......',,,,,,,,,,'''';ldxxkxl,.        ..';oOkdo;....,d000OkkkOKKOdodkOxdoooldkOKKkc'','...,;'....,;....................';'...    //
//    ..'xNNWWWWWWWWWWWWNXXO:.............''''',,;cdkkddxo:....       ..,c:'',,'...';c:'.;cclxkxdoo:,,;;,,,',::::,..;c'..,;'....;;....................';'...    //
//    ..'xNNWWWWWWWWWWNNNXXO:.....................'lkkodxoc....       ..'.';::;;,,,;;;:;,...'cdxxo:..;lc:;;,,;;::;...:;..,;'....;,....................';'...    //
//    ..'xNNWWWWWWWWWNNNXXXO:......................:ddddxxl'.'...... ...';;,;:clloolc:;,,;,..'cl;,,;;;,;:cllllc;;,;;..'..,:'....;,....................';'...    //
//    ..'xNNNWWWWWWWNNNXXXXO:.....................,coodxxo;.....,:,.  .,c;,coddddddddddl,,c:.'oo'.:c,,ldddddddddo:';c,...,;.....;;....................';'...    //
//    ...oKNNNNNNNNNXXXXXXKkc''...................'lxddxdoc.......... 'l;.;cllc;'''''';c:',l;.lo';l,':lll:,'''',:c;.;c'..,:'....;;....................';'...    //
//    ....;lxOkkOOOOOkxdol:;,,,,;;;,,,''..........'cdddxddl,..   .... ':,l0KKXk'      ;0Kd;;;.;:';;;d0KXKo.    .oKOc,:'..,;'....;;....................';'...    //
//    ......;:'..'''...............'',,:;.........'lkxddddlc:'........,c,oKWWMK,      :XXx;::.;:'::;xXWWWx.    .xNKl,c,..;;.....;;....................';'...    //
//    ......;;.........................;;........,;lxxooo:,,;,..''.....c::kXWWXxccccclkXOc;l,,dx;;l;cONWWKocccco0Xx;:c'',;;.....;;....................';'...    //
//    ......;;.........................;;.......'ldoddlc;;;;;::;;'.....'c:;d0NWWWWWWWNKx:;c;'lkk:.;c;:xKNWWWWWWN0o;:c,..........';;,,,,,,''...........';'...    //
//    ......;;.........................;;......':dkdxxo;;lolc:c,.........,;;:loxkkkxdlc:;,''lxl:'  .,;:codxkkxdl:;;,.,lo;.............'',,,,,,,,,,,''.,:'...    //
//    ......;;.........................;;........cdddxdccdooool;......'.  .,;:::;,;::::;'',:c;...   ..;::::;;:::;,,',;lkd,......................'',,,,;;....    //
//    ......;;.........................;;........';clllccoolllc,........    .,,'...'',',,',,'....       ..........;:cllxx;..................................    //
//    ......;;.........................;;..........,;:lc:cllc:;,......      .;c,....'',,'..'..','.              ..,;:dkOd'..................................    //
//    ......;;.........................;;..........,cldd::cclll:....         .;c;'..........',:;'..     .      ...,:oxOkc''.................................    //
//    ......;;.........................;;..........'cxOOl:cloddc...           .'::;'  ....':llc;....          ....;cd00d;,,,,,,,,,,''.......................    //
//    ......;;.........................;;...........;cllc:coool;..             ....'.  ..,lkKOdl;.           ....:dxddl,........'',,,,,,,,,,,''.............    //
//    ......;;.........................;;.............'',;looo:'.           .......    ..;lONKkko,.      .......'dKK0Ol'..................'',,,,,,,,,,,'....    //
//    ......:;.........................;;..............,lllodxo,.         .;lc:::;;;,'....',::,,,,'',,;;;,,',:;.'xXKkocllcccc:;,'...................'';;....    //
//    ......:;.........................;;.............',ldoodxd:.        .:o:.    ...,;;::::::::cc:;;'..     ,l;,xOo,.',,,,,;:cclc:;'.................';'...    //
//    ......:;.........................;;.............,,;xOkkxdl.        .co;            .........          .:o;c0k:............',:llc,...............';'...    //
//    ......:;.........................;;.............;,'codkOd:.......   'lo;.                           .,ll:cOXx,................,:ll;'............';'...    //
//    ......:;.........................;;.............;;..';x0x;',,'..     .:ol:,'..                  ..,:lc;.'xXKo'...................;cl;...........';'...    //
//    ......:;.........................;;.............;;.';cx0Oo::;..        .;looooc:;,'..........,;:cc:;....:ddc,......................;lc,.........';'...    //
//    ......:;.........................;;.............;,.:oxxkKXOl:;.           ..';:loooooollllccc:;'..  ...':;'.........................'cl;........';'...    //
//    ......:;.........................;;.............;,.cxOkkKW0lcl,.                ..''''''....    .. ...,oc,';,.........................:l:.......,:'...    //
//    ......:;.........................:;.............;;,dkkkxkX0oc:'.        ..........','.'''...   .....',ld;;lo:..........................;l:......,:'...    //
//    .....':;.........................:;.............;;,:cc:cdOOd:,.      ..,;::::col;:xxc:cllll;.........;do';xko'..........................;l:.....,:'...    //
//    .....':,.........................:;.............;;;,;:clool;..     ..,clcc:c:;::::odc:;;;:;:c;'....,',lc,,lo:............................:l;....,:'...    //
//    .....':,.........................:,.............:;''',;,....   .  ...',,,,,''..,:ccc;,'......,,,.....,:;;:c:'............................'lc'...,:'...    //
//    .....':,.........................:,.............:,..........        ..........,coc;,'.....     .........cxo,..............................:o;...,:'...    //
//    .....':,.........................:,.............:,..........         .,'.  ..............      ....':'..,lc;'.............................,lc...,:'...    //
//    .....':,.........................:,.............:,.........          .,'.  .....   .''..       ....,ll;.,coooolcc::;;,,''.................'cl'..,:'...    //
//    .....':,.........................:,.............:,.....','..   ...   .,,......'..  .ll..       .....cdooooddddddddddddooollcc::;;,''.......cl,..,:'...    //
//    .....':,.........................:,.............:,.......'''...''....';;'....',,'...::..        ....,cooodddddddddddddddddddddddddoollc:'..co,..,:'...    //
//    .....':,........................':,............':,........':::clc:ccc:ccc::clodoc;;;:::,..........   .,:clddxxdddddddddddddddddddddddddl,.'ll,..,:'...    //
//    .....':,....................;:'.':,.........codxx;.........,,;cccooolcccclllx0kl:;;::cdxl:;::;,,;'......';odxxdxxxxxdddddddddddddddddddc..;oc...,:'...    //
//    .....':'...................:kOc.':,..;ool;..;lx0O:..'coo;....','';;;;:llldxxOKko:,,,,:kKxcclcccclc::;'.':odddxxddkOxddddddddddddddddddl,..co;...,:'...    //
//    .....':,..........'.........;dx:,:;':kK00kc:cclxxol:ck00d;'',cc;;:cccccllodddxdc;,,,,:dOxl:;,,'',;,....,lkxddkxxkOkxdddddddddddddddddo;..;oc'...,:'...    //
//    ..,:,;c;,,..'',;,':ooddl::cclkKxlooooxO000kkkOOOOOkoodxdlcllllcldoc:;;;;:::::c:;;::;;;:oo,'''....'.   .'cxkxddxxdxOOxdddddddddddddddo;..,ll,....,:'...    //
//    .,dOxl:,,;,:dxkd:;oxkKKOodkOk00kxxxxxoldkO00KKOxxk0000kxololc::clcclc::ccccc;''',;;,,'';;,;;;'.....  ...:x0Okkkxdkkxdxkxdddddddddddl,..;ll,.....,:'...    //
//    ;::okd;,:ldk0000OxdxO00000KKK0KKKK0ko:,;;o0K0Oxodk000000Oo:;;clllxkoloxkO0K0o,;:cll:'...':okd:',;,'..',;lkO00KX0xdxxxkxxdxkO00kdol;'.':ol,......,:....    //
//    ,,,l0KkxO0OOO0K000OOkxxxkOkxdxO0K0Odc:cccoxxxdodk00000KKKkoldxddO00Oxoc:codo:,lk000Oc..;lx0KKOO000OkkOOxdk0000KK0000000OOO0KKKkl;':oxxd:'.......,:'...    //
//    oxkOXXKKK0OOOOO0KK00kxxxdxxxkO0Okdolodkdcldddloddk0000O0Kkdddxxk0000koclc;'..,dK0OOOxxOKXNNXXXXXXXXXXKK0xx0KKKKKK0KK00K0OOOO0OOkdokK0Oc.........,:'...    //
//    0K00KKKKK00OOkxkO000kxkOO000K00kxl::lxOxlloollllooxxkkxxkdddldkkOkO00OOOkx:.';ldkOkxOXNNNNXXNNXXXXXXXXXKOO0KKKK0OO00OO0K0OOdodddxxkkd:..''......,:....    //
//    xxkO0KKKK0kkxdxdoxOxddk0000000K00kox0KKKOxdoooolllllodlcclxxdlodooxk00000xc;:cok0000XXKKXX00XNNNXXNNNNNXKKKK0OkOO00OkkO0000kolookOOkkdc:oo::,.'';;....    //
//    xxdxOK0OkkxdodkkodOkxddk0KK00OkkxddO00K0OxxkOOkdoolloddddkOOkxxdclldkOOOkooxO00000KXXX0O00OO0KXNNXXXXXXXXK0000OkO000OOKK0kkkxdkO0000000OO00Oxc;clo;...    //
//    xxxdxkkxoodxxxOOdk00Okk0KK00kxxdooldk0KOo:cok0Odll:;:lxkddxxxkxdoloxOxlllllldO0000K00OOkOOOOkOKXNXXXXNNNNX0kO00O00000KK0OkxddxxxO000K0000OO00d;;oOko;'    //
//    dddxkxkOxxOKKK0xldkkOO0XXXXXOxddddoddkOko:,:okkkOxc:codxxdoooollllloxdc;,,,,;lkOkxOK0OOkO0KK0OOKXNXXXXXXXXKkxkOO00K0000OOOkxxxxdxO000OOOOxxOOk:.:xO0Oo    //
//    ooodxxdddk0K0KKkdkOO00OxkO0KKOkxxxddxxO0Okdc:lloxkookkdxxkxdolldxkxoooolc:;,,,;:;ckXNKOO0XNNX0O0XNNXXXXXXNX0kO0000K0000OkkkkxddxxxOOkkO0KOxxkOd;;lxkkx    //
//    ddddxxxxdx0XK0OxkKKK00K0Okxddk0kxxdddk0000kollllododkkkOOOkdoddkO0OdldkOkxolllc;,:xXNX0OOKNNXKO0XNNXXXXXXXXXK0OO00KKKK00kkxxdxk0OxdxkO00K0xkO00OkxxxkO    //
//    kkO0KKOxddk0kddddxxxoloxO00kx0KkdddxddkOkOOOkxddoooddkOOkxocldxxk0OdloxO00kdollc:ckXNXKOO0000OOKXNNNXXXXXNNXK00O00K000KK0kxxxO0K0OxdxxkOK0kOXXXK0kxkOO    //
//    OOO00Oxdoccl::oxxdolcc::cd00KKOddxxdooddddk00OkxoodddkOOkxoclddoddoodxxxxdoc::cldk0XNNKOkkkkOkO0KXNNXXXXXXXXKKXK0O0KKKKX0OOO0OOO00OxxdxkOOxxk0XXkox0XK    //
//    dxxdddl;:oxkxxkkxl::ccc::lk000OO000OdloddlldxxxddkOkxxkkkkxdodoc:;;cloddocldxkO0KKKXXNX0OOOKKK0OO0XNXXXNNNNXKOOOOO0KXK00OO0Okxxxkkxddxkkoldxddk0kookKK    //
//    xxxdddc'l00000kc,',;;..',:dOO0KK00OxoloddlccldxddxxxddxkkxdoloxxdddddollxkkO0XXKK00KXNXKOO0XNNX0OOXNNXXXXXXXKOkkO00KKKK00OkxdoooddddkO0koxkkxdk000OO00    //
//    oodkkxolodl;,,....';,;:;'.';ck00kxdooodolccllodxdodxddxddxdoox00000OOkdok0KK0OxdxxldKNNKOO0KXXKOkOKNXXXXXXXXK0OO00KK0000kxdooccoddxO0KKxlx00OkO00OxkKX    //
//    kkO00Okxdl'      ..,'.';;..'cddxxxdoddkkxollllloolldxxxxxkkxxdxkOOOkxkO00Okkd:',:;;lOXXKOkOOOOOkO0XNXXXXXXXXX0O0000OkOOkdddddodxxddxxxdoodxk00Oxc,,:ok    //
//    k00000Oxxo'       .'.  .'..:oddkOxdddk000xlcllloollodxkkO000kxdddkkxxk0K0klc;.,c:,:dOKK0OkkkkkkkOKNNXXXNNNNX0kkO00OkkkkkdddxddxkOxddl:;:cc;ckdl;...';l    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract COMIC is ERC1155Creator {
    constructor() ERC1155Creator() {}
}