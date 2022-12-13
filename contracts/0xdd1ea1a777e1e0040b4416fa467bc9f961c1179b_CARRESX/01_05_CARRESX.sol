// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Carres Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNWWWWWMWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWOllllllllllllllllllokNMW0od0WNx:;lOWXdloooooollllllllllllood0NMNxllldKWKxolloooooooooooooooooooooooooooood0WWWWWWW    //
//    WWWWWNx;,'''''............,OMXc..;0X:...cXO;......................cXMXc....dNd..................................,0MWWWWW    //
//    WWWWWW0lcx0000000000000x,..xWNc..'OX:...;0WX0OOkkkkkkkkkkxxxxxxxxkXWWWx...;0WN0kxddoooooooolollloodddxxxxxdo;....kWWWWWW    //
//    WWWWMWo..:KWWWXOddxKWWWNl..oNNo..'OXc...,OMXkollooooooooooooooooodOWMXc...dWWN0kxdddxkOKNWWWNxc:lxKWWWOllkNMO'..'kWWWWWW    //
//    WWWWWWo..,OMNx;....'oXMNl..lNWd..'kXc...'kWk'.....................cXMK:...cKWx'........':o0WNo'...;kWK:..,OMO,..'kMWWWWW    //
//    WWWWWWd..'kMk.......'kMX:..oNMk'.'kXc...'kMN0xdoollllllllllllllloxKWWWk,...oN0o::::;,.....,kWNx'...;0K:...oWO,..'kWWWWWW    //
//    WWWWWWd..'kMKl,....,lKWNkldKWWk'.'kXc...'kWWX0OO000000OOOOOOOOOOO0XWWWK:...oNMWXOkxkOOl'...;0MNl...'kNl...lNX:..'kWWWWWW    //
//    WWWWWWx'..dNWWX0OO0KNWWWNNWWWMk'.'kNl...'kWk;.....................oNWWx'..;0MNk;....,xXd....dWWx'..'xNo...cXW0l,:KWWWWWW    //
//    WWWWWWk'..':llllllccccc:::cOWWd..'kNl...,OW0ollllllllllllllccllllo0WWK:...dWWk'......;00;...lNMx'..'kWo...cXWWXOKWWWWWWW    //
//    WWWWWWNklc;,,''''''''''',,c0WK:..'kNo...'dKKKKKKKKKKKKK0000000KKXNWWW0,..'xWWO,......cX0;...lNWx'..,ONo...:XXo;,:OWWWWWW    //
//    WWWWWWWWWWNXXKKKKKKKKKKK0KXKk:...'OWo.....''''''''''''''''''''',;:xNWNl...:KMWKdlcclxKXo...'xWNl...;0Xc...:XO,...oNWWWWW    //
//    WWWWWW0ooooooooooollllccc:;,.....lXWO:,,,,,,,,,,,,,,,,,,,,,'......,0WW0;...lNWXkxxxxdl;...'oXMO,...lNK:...cXN0xxkXWWWWWW    //
//    WWWWWWd''...................',;:xXNKKOkkkkkkkkkkkkkkkxxxxk00Ox:...'kWWXc...;KXc.........'ckNWO;...'kWk'...lNNkllxXWWWWWW    //
//    WWWWWWNOodOOOkkkkxxxkkkOOO00KXXWWk;'''''''''''''''''.....':0MMx'...xWWK;...lNNx:;;;:clox0NWXd,....lXXc...'xWO'...lNWWWWW    //
//    WWWWWWKc.'dNWWWXOxxOKWMWMWKOxkXMK:......''',,,,,'''''''',,lKMWO:,;c0WNo...;0WWWNXXXXXXXK0xl;....'oXNd'...cXMXkold0WWWWWW    //
//    WWWWWMO'..;0WOl,..'',:lol:'..:0M0,....lO00000000000000000KXNXXXK0KNWWK:...dWW0dlc::;;,,'......'cONXo'...:KWWWXOk0NWWWWWW    //
//    WWWWWWO,..,ONdcldOK0kdlllodk0XWW0,...;KO:;:::::::::::;;;;;;;;;;;;;oKMNo...xWO,.............,cd0NNk:....lKWWW0:..'xNWWWWW    //
//    WWWWWW0;..,OMWNXKOOO0XXXK0OkxONMO,...:KO:,''''''''''''''',,,,'....'xWWk'..lNKl,,,,;;;:cloxOXNXOd:....;kNWWWW0:'',xNWWWWW    //
//    WWWWWW0;..,ONkc;'...',,,,'...,OMO,...;KWNX00OOOOOOOOOOOOOO0KXKk;...xWMO,..;KWWXXKKKKKKK00kdoc,.....;dXWNKXWWWXOkKWWWWWWW    //
//    WWWWWW0,..'ONx;,;lxkxolcccclokNMO,...;KMXdc::::::::;;;;;;;:dOXXc...dWWd...:KWKdlc::;;,,'.......';lkXWXx:,cKMXo;;l0WWWWWW    //
//    WWWWWW0,..'OMN0xxkOO00OOOOOO0XWM0,...,0Wx.................'lkXXc...dWNx:::xNK;...':cllloooddxkO0XN0ko;...,0MO;...oNWWWWW    //
//    WWWWWW0,..'OMk,.............',kWK:...;0Mk'..'lkkkxdddddddxkXWWXc...dWWNKKKKOc...c0NWWNXXKKK0KXWWXl'......;0MW0ddONWWWWWW    //
//    WWWWWW0,..'OWd................lNWKxxx0WMk'..:KWk;,,,,,,,,,,o0NXc...dWOc;;;,'...:KMXxc;,,''''',oXO,.......;0Nk:,,oXWWWWWW    //
//    WWWWWWO,..'OWo................lNWKOkkkkd;...:KNl...........:kXXc...xWk;',,',,;l0WWx...........:00,.......;0O,...'OWWWWWW    //
//    WWWWWWO,..'ONo................lNK:.........'dNNl...........:kXXc...xWWXKKKKKXNWWXx,....cxOOOO0XWXl'....''lX0,...,OWWWWWW    //
//    WWWWWWO'..'kNl................lNNOollllllox0NMNl...........:OXWk;.,OWN0xddddxdoc,....'xNNXKKKKKKKOxdddoodkOl'...;KWWWWWW    //
//    WWWWWW0,..'kNl................lNWKOkkkkkkkkOKWNc...........c0XMNOdxOx:..............;kXk:,'''''''''''...........lNWWWWWW    //
//    WWWWWWNx;,lKWOc;;;;;;,;;;;;::l0WKc..........;ONc...........lKNXo,'''.......';lodddxOXWXc.......................;OWWWWWWW    //
//    WWWWWWWWXKNWWWNXXXXXKKKKKXXXXNXKd'...,;;:::cdXWKxdxxxxxxxxkXWWK:......'';cdO0kdoodxOXNWXOxxxddddddddxxdxxxxkkkOXWWWWWWWW    //
//    WWWWWWKoccccccccccccccc::::::;;,....cKNKkxxkkkkkkkkkkkkkkkkxxOXN0kdddxxkkkdl;.......,:looolllox0NWWWWkclxXWOlc::l0WWWWWW    //
//    WWWWWWO;,,,,,,,,,,',''''''''''''',;l0WK:......................dW0:,',,,''...':ldddl;'..........':kNWWx'..:0x'...'kWWWWWW    //
//    WWWWWWNOxkOKXXKKKOdodxO0K000OxddxxONMWd.......................cXKl;,,;;:cldkKKxoloOK0kxddddo:'...'xWMXc...dXo...'kWWWWWW    //
//    WWWWWWO;.';:lxOXWXl..';cxKWNd'.''''lKNd.......................lNMXOxkkOOOKNMXl.....cKWWWN0xdxkdc:cOWMKc...dW0;..'kWWWWWW    //
//    WWWWWWk'......';o0Xk;....;0Wd'...'',kWXOdoollllllllllllllooooxKWMKl;;;;,':0MO,......lNW0c....cKWNWWKx:...,OWO,..'kWWWWWW    //
//    WWWWWMO'.........;KWo....'kWNK00OkkkOOOkxxdddddooooooololllolooodddddxxkOKWMKc......lNK:......oNMXo'....,kWKc...'kMWWWWW    //
//    WWWWWMO,.......,l0NO;...;kNXkolc:,,'..................................',:ldkK0xolllxXMO,......:XMO,....:OWKc....'kMWWWWW    //
//    WWWWWWO,....':xKXOl'..,oKWK:......'',;;::cclloooodddddddddddddoolc:,'.......':okKNWMWWWOl::::lOWM0,...:KMKc.....'OMWWWWW    //
//    WWWWWWK:',cd0NMKc..':xKWWMXdcloxO000OOOOKNWWNkdd0NMWXkddxOXWWWWWWWX0kxdl;.......';coddxxddolloONM0;..'xWNo......'OMWWWWW    //
//    WWWWWWWX0KXK0KNXkdx0K0xddxO0KK0Oxoc:,''',c0WO,..'xWWo.....,lxONWNx;,;:lxO0ko:,................lNM0;..'xM0;......'OMWWWWW    //
//    WWWWWWXdlc;,'';coooc;'.....''''..........'xWk'...oNWKo'.......cONKl'....,lkXNKOxoc;,''''',;:lxXWKl....dW0;......,OMWWWWW    //
//    WWWWWWx..............';:cc:;,,,;:clooooox0NMO,...oNWWWKd;......'lKNOl'.....;o0NWWWNXKOxk0XXNWWWO;....'xWNx'.....,OWWWWWW    //
//    WWWWWWXxooddxddoolodk0KXXXXXKKKXNNNNXKKKXNWMO,...oNNOx0NXx:......,dXN0l,.....'cxKWWWO:',cONWWWWk,...'lXWWW0o;''':0WWWWWW    //
//    WWWWWWKo::l0MWNK0Okxol:;;;:cllllc::;,,'',oXMO,...oNx'.'cONNOdl'....,dXWKd;......,oXWd....;KWWWWN0dox0NXOkOKNXK00XWWWWWWW    //
//    WWWWWWk'...xNd;,'.........','............;KMO,...oNk,...'ckNWW0o,....,dKWXkl;....,OMx'...;0W0lcldxxdoc,...':ccccxXWWWWWW    //
//    WWWWWMO,..'xNx:;,,,,;:coxO0000OxddoolllooONMO,...lNWO:.....:oxXWKo,....'lONWXOxdd0NMk'...;0Wx'...........'......'kWWWWWW    //
//    WWWWWMO,...xWWNX0OOOKNWWXo:::ccllloooddxkXWMO,...lNMWXo,......;dXWKo'.....:xKWWWWWWMk'...;0MNOl:;;:cloxO0K0kdlclkNWWWWWW    //
//    WWWWWM0,...xWW0o:;,;:oOWXc...............xWMO'...lNWXNW0c.......,dKN0o,.....,lkXWWWWO'...;0WX0KK000OkxoollxXMN0kKWWWWWWW    //
//    WWWWWM0,...xWO,.......'xWK:..............xWMk'...lN0::xXNk;.......,oKWKx:......,oKWMO,...;0Kc.',,,'.......'kWd'.:KWWWWWW    //
//    WWWWWM0;...xWd.........:KNo..............xWMk'...lN0;..;kNXdc;......;OWWNOo;.....;0MO,...;0O,..............oXo..,OWWWWWW    //
//    WWWWWM0;...dWk'........lNNo..............xWMk'...lNWOc'..dWWWKxc,...'xWWWWWXOo:,.;OM0,...;0K:..............lNk'.,OWWWWWW    //
//    WWWWWM0;...dWNkc:;,,;cxXMWOcccccccccllllxXWWk'...lNMWNOdo0WWWWWNKkxxOXWWWNNNNXKOOKWM0;...;0WKOkkxxxxdddddoxKNo..'kWWWWWW    //
//    WWWWWW0;...;oddoolcloodddddddoododooooooooxXk'...lNXxlccccccccccccccc:::::;;;;,,;ckNK;...;0Xxlcllllllllllool:'..'kWWWWWW    //
//    WWWWWWK:..................................;0O,...oNx'.''''''''''..................lXXl...:K0;.'''...............,kWWWWWW    //
//    WWWWWWWKOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkOKWN0xxkKWNKKKKKK00000000000000000000000KNWWXOkOKWWK0000000OOOOOOOOOOOOKNWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CARRESX is ERC1155Creator {
    constructor() ERC1155Creator("Carres Editions", "CARRESX") {}
}