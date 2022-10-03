// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fe-MALE / As Strong As Iron
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    KXXXXXXXXNNNNNNNNNNNNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNWWNNNNNNNNNNNXXNX    //
//    KXXXXXXXNNNNNNNNNNNNNNNNWNNNNNNNNNWWWWWWWWWWWWWWWWWWWNWWWWWWWWWWWWWWWWWWWWWWWNNNNNNNNNNNNNNNNXXXXXNK    //
//    KXXXXXNNNNNNNNXXXXXXNNNNWNNNNNNNNNNWWWNNNNNNNNWWWWWWNNNNNNNNNNWWNNNNNNNNNNWWNNNNNNNNXNNNNXXXXXXXNNNK    //
//    KXXNNNNNNNNNNNXXXXXXNNNNWNNNNNNNNNNWWNNNNNNNNNNWWWWWNNNNNNNNNNWWWNNNNNNNNNWWNNNNNNNNNNWNNXXXXXXXXNNX    //
//    KXXXNNNNNNNNNNXXXXXXNNNNWNNNNNNNNNNWWNNNNNNNNNWWWWWWNNNNNNNNNNWWNNNNNNNNNNWWNNNNNNNNNNWNNXXXXXXXXXNX    //
//    KNXNNNNNNWNNWNXXXXNNNNNWWNNNNNNNNNNWWNNNNNNNNNWWWWWWWNNNNNNNNNWWNNNNNNNNNNWWNNNNNNNNNNWNNNNXXXXXXNNX    //
//    KK00O0OO0KNNNNNNNNNNNNNWWNNNNNNNNNNWWNNNNNNNNNWWWWWWWNNNNNNNNNWWWNNNNNNNNNWWNNNNNNNNNNWWNXXXXXXXXXNX    //
//    X0lc:cc:clONNOddddoddkNWWNNNNNNNNNNWWNNNNNNNNNWWWWWWWNNNNNNNNNWWWNNNNNNWNWWWNNNNNNNNNNWWNNNNNXXXXXNX    //
//    XO,.......oNXl.......cKWWNNNNNNNNNNWWNNNNNNNNNWWWWWWWNNNNNNNNNWWWNNNNNNWWWWWNNNNNNNNNNWWNNNNNNNXXNNX    //
//    XO,.......oNXl.......cKWWNNNNNNNNNNWWWNNNNNNNNWWWWWWWNNNNNNNNWWWWNNNNNNNNNWNkllxXNNNNNWWNNNNNNNXXNWX    //
//    XO,.......oNXl.......cKWWNNNNNNNNNNWWWNNNWWWWWWWWWWWWNNNNNNNNWWWWNNNNNNNNNWW0c:ONNNNNNWWNNNNNNNXNNWX    //
//    XO,.......oNXl.......cKWWNKKKKKKKKKNWNNNNWWWWWWWWWWWWNNNNNNNNWWWNNNNNNNNNNWWNlcXWNNNNNWWNNNNNNNXNNWX    //
//    XO,.......oNXl.......:KWWk;,,,,,,,:OWOkXNNNNNNWWWWWWWNNNNNNNNNWWWNNNNNNNNNWWNlcXWNNNNNWWNNNNNNNXNNWX    //
//    X0,.......oNXl.......:KWNd'.'..'.',dNOxXNNNNNNNWWWWWWNNNNNNNNNWWWNNNNNNNNWWWNlcXWNNNNWWWNNNNNNNNNNWX    //
//    X0,.......oNXl.......:KMNo'......'.lXNNWWWWWWWWWWWWWWNNNNNNNNNWWWNNNNNNWWNWWNkkNWNNNNWWNK0NNNNNNNNWX    //
//    X0,.......oNXl.......:KMXc.......'.;0WWWWWWWWWWWWWWWWNNNNNNNNNWWWNNNNNNNNNWWNNWNNNNNNWWNkkNNNNXNNNWX    //
//    X0;.......lNXl.......:KMK:.........,kWWWWWWWWWWNNWWWWWWWWWWWWWWWWNNNNNNNNWWWNNNNNNNNNNWWOONNNNNNNNWX    //
//    X0;.......lNXl.......:KM0;.........'oNWWW0lccclccclloxKWWWWWWWWWWNNNNNNNNWWWNNNNNNNNNWWWKXNNNNNNNNWX    //
//    X0;.......lNNl.......:KMO,..........cXWWWk,''''''....':OWWWWWWWWWNNNNNNNNWWWWNNNNNNNNNWWNNNNNNNNNNWX    //
//    X0;.......,cc,.......:KWk'..........;OWWWk,.'''''...'..cXWWWWWWWWNNNNWWWWWWWWNNNNNNNNNWWNNNNNNNNNNWX    //
//    X0;..................;KWd.....,'....'xWWWk,.'.'ok:.....:0MWWWWWWWWWWWWWWWWWWWNNNNNNNNNWWNNNNNNNNNNNX    //
//    X0;..................;KNo....'c:.....oNWWk,...'kNo.....:00oddoodx0NWWWWWWWWWNNNNNNNNNNWWNNNNNNNNNNNX    //
//    X0;..................;KXl....'do.....:KWWk,...'xNo'..'.:0d.......,lKWWWWWWWWWNNNNNNNNNWWNNNNNNNNNNNX    //
//    X0;........;:'.......;0K:....'xx'....,OWWk,...'xNo'....;0d'..,;,'''dNWWWWWWWWNNNNNNNNNWWNNNNNNNNNNWX    //
//    X0;.......cXXl.......;00;....,kO,....'dWWk,...'ok:.....:0d...c0o...lXWWWWWWWWWWWWWWWWWWWNNNNNNNNNNWX    //
//    X0;.......lXNl.......;0O,....,OK:.....lXMk,....''.....,dXd...cKo...lXXdooooodKWWWWWWWWWWNNNNNNNNNWWX    //
//    X0;.......lXNl.......;0k'....;0No.....:0Mk,.'........'lKNd...lKo...lX0:''''':kXXNWWWWWWWNNNNNNNNNNWX    //
//    X0;.......lXNl.......;0x.....;0Wx'....,kWk,.'..,;'.....lKd...cKo..'lXNKk;.,xXk::OWWWWWWWNNNNNNNNNNWX    //
//    X0;.......cXNl.......;0d.....':c;'.....dWk,...'dKo'..'.;Od...cKo.'.lNWW0:.;OWk,,kNNNWWNNNWWWNNNNNNWX    //
//    X0;.......cXNl.......;Oo...............cXk,...'xWx,'...,kd''.cKd.''lNWW0:.,OMk,,dd::xkc:oXWWWWWWWWWX    //
//    X0;.......cXNo.......;kc...............;0O,.'.'xWx,'...,kd''.cKd.'.lNWW0:.,OMk,,dc..cl'.:0KOKNWWNWWX    //
//    X0;.......cXNo.......;x:.....',;;,.....'kO,.'.'xWx,'...,kd''.cKd.'.lNWW0:.,OMk',dc.'','.:d:cOXKKNNWX    //
//    X0;.......cXNo.......;d;.....lKXXd'.....dk;.'.'dWx,'...,kd...cKd.'.lXWW0:.,OMk',dc,:'.;,:d;dXx:oKNNX    //
//    X0;.......cXNo.......;o,.....dWWWO;.'.'.cx;...'dNx,'...,kd...;o:.''oNWW0:.,OWk',d:,l,'l;:d;cKOcx0x0X    //
//    X0;.......cXNo.......;c,....'xWWWKc.'.'.;o;.'''dWx;'.'.,kd.......'lKMWW0:.,OMk',d:;x:,d::o;dX0llxxOX    //
//    X0c,,,,,,,oXNx;;;;;;;co:;::;c0WWWNx:::::ldl:ccckWKkocccckxccc:cloONWWWWXo:l0W0clkdl0xd0ooklcxklokOKX    //
//    KX00000000KXNXKKKKKKKKXKKKKKKNNNNNXKXXXXXXXXXKXNNNNNXXXXXXXXXXXXNNNNNNNNXXXXNXXXXXXXXXXKKXKKKXKKXKKK    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FeML is ERC721Creator {
    constructor() ERC721Creator("Fe-MALE / As Strong As Iron", "FeML") {}
}