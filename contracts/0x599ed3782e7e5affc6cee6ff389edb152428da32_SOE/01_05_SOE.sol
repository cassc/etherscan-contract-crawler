// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Shapes of Earth
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXKOOOOOOkkkOOOOOOOOOOOOkkkOOOOOOKXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWX0OkkkO0KXNWMMMMMMMMMMMMMMMMMMMMWNXK0OkkkO0XWMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMWX0kkkOKXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0Okkk0XWMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWXOkkOKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKOkkOXWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMNOkkOXWMMMMMMMMMMWWWNWMMMMMMMMMMWWWWMMMMMMMMMMMMMMMMMMMMMWXOkkOXMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMWKkxOXWMMMMMMMWN0dolc::cdxdodxxxdlcc::cldkXMMMMMMMMMMMMMMMMMMMMWXOxkKWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMW0xx0NMMMWNNWXkdc;'.;c;'..... ...........ck0NMMMMMMMMMMMMMMMMMMMMMMMN0xx0WMMMMMMMMMMMMM    //
//    MMMMMMMMMMMW0xxKWMMMMNo,;c;....;dKWNX0o.............,xNMMMMMMMMMMMMMWNXXNWMMMMMMMMMWKxxKWMMMMMMMMMMM    //
//    MMMMMMMMMMXxx0NWWWNXOl.....'c:...cKWMWk'.......';:clkXNMMMMMMMMMWXkl;,'',:ldO0kkxdoloO0xxXMMMMMMMMMM    //
//    MMMMMMMMNOdO0o::;;,'...,cod0Kl..'c0WMO,....;cx0XNKOd::dXMMMMMMWKd,...................'o0OdONMMMMMMMM    //
//    MMMMMMMXxx0k;......;ok0NN0l:;'':OWMMMKc',l0NWMMMMWXKkOXWMMWMMKl.....ol'................,k0xxXMMMMMMM    //
//    MMMMMW0dO0l........l0XWKo.......xWMMMMNXXWMMMMMMMMMMMMMNKdlOWXd'..'oOl'..................l0kd0WMMMMM    //
//    MMMMWOd0O:...........,c;........,kWMMMMMMMMMMMMMMMMMMMXl'..'oxo'.',;'.....................:OOdOWMMMM    //
//    MMMWOd0O,...................,c:..lXMMMMMMMMMMMMMMMMMMMXkdc.................................,k0dOWMMM    //
//    MMWOd0k,....................;O0dlkNMMMMMMMMMMMMMMMMMMMMMNk,.................................,k0dOWMM    //
//    MM0dOO,.................;odldKWMMMMMMMMMMMMMMMMMMMMMMMXxlc,..';c;............................,OOd0MM    //
//    MXdk0:...............'lONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk. ...lKNNKd;:o;.',.....................;0kdXM    //
//    WkxKl...............lKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKc..,:lol:l0NNWKxO0o;,,..................lKxkW    //
//    Kd0k'............'ckNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXd'.........,d00dldkkxkx;.................'kOdK    //
//    xxKc.....,;';c,.'kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKc...............................,..........c0xx    //
//    dOk'...'dXNXNWKc:0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0x,...............................'cl;..''....'kOo    //
//    o0d....cNMX0XMMNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo'...........................':'.........cOK0x:;x0o    //
//    dXO;...'od;,kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK;.............................'c,.......:xNMMMWNNNd    //
//    dWMXOoc;'...;oKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0, .............................'c;...,l0WMMMMMMMMWd    //
//    dWMMMMWWXko;..oNNXOxxx0KXWMMMMMMMMMMMMMMMMMMMMMMK:...............................'ll:lOWMMMMMMMMMMWd    //
//    dWMMMMMMMMMNx:;::,......,cxKWMMMMMMMMMMMMMMMMMMMMXOd'................................'xWMMMMMMMMMMWd    //
//    dNMMMMMMMMMMMNX0:..........';lkNMMMMMMMMMMMMMMMMMMMWO:'.',;clc,......................:KMMMMMMMMMMMNd    //
//    oXMMMMMMMMMMMMNx'..............dNMMMMMMMMMMMMMMMMMMMMWKKXNWWMWNx'..................:xXMMMMMMMMMMMMXo    //
//    o0MMMMMMMMMMMMk'................;cdkOKNWMMMMMMMMMMMMMMMMMMMMMMMO'................'xNMMMMMMMMMMMMMM0o    //
//    dkWMMMMMMMMMMWx......................';xNMMMMMMMMMMMMMMMMMMMMMMNx'..............'xWMMMMMMMMMMMMMMWkd    //
//    OdXMMMMMMMMMMMK:.......................cNMMMMMMMMMMMMMMMMMMMMMMMWd..............:KMMMMMMMMMMMMMMMXdO    //
//    NdkWMMMMMMMMMMMKo'....................:0WMMMMMMMMMMMMMMMMMMMMMMMMk'..............kWW0kXMMMMMMMMMWkdN    //
//    M0d0MMMMMMMMMMMMWO,..................;KMMMMMMMMMMMMMMMMMMMMMMMMMNc..............:O0l''kMMMMMMMMM0d0M    //
//    MWkdXMMMMMMMMMMMMWKd:................lNMMMMMMMMMMMMMMMMMMMMMMMMMNl............cONK:..;0MMMMMMMMXdkWM    //
//    MMNxxNMMMMMMMMMMMMMMK;..............:OWMMMMMMMMMMMMMMMMMMMMMMMMMMK:..........;KMWx. .xWMMMMMMMNxxNMM    //
//    MMMXdkNMMMMMMMMMMMMMX:...........;x0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMk. .......,OWMW0l:xNMMMMMMMNkdXMMM    //
//    MMMMXxxNMMMMMMMMMMMMX:..........,0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo.......;OWMMMMWWWMMMMMMMNxxXMMMM    //
//    MMMMMXxxXMMMMMMMMMMMNc.........'xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl.....;0WMMMMMMMMMMMMMMXxxXMMMMM    //
//    MMMMMMNkd0WMMMMMMMMMWo.......,dKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXkdxxkXMMMMMMMMMMMMMMW0dkNMMMMMM    //
//    MMMMMMMW0dkNMMMMMMMMWd......:OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNkd0WMMMMMMM    //
//    MMMMMMMMMNkd0WMMMMMMMKc....lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0dkNMMMMMMMMM    //
//    MMMMMMMMMMWKxxKWMMMMMMO' ..oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxxKWMMMMMMMMMM    //
//    MMMMMMMMMMMMW0xxKWMMMMNd...cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxx0WMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWKkxONMMMWOo,'dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOxkKWMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWXkxkKWMMMXk0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0kxkXWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMN0kkk0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0kkk0NMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMNKkkkOKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKOkkk0NMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMWX0OkkO0KNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNK0Okkk0XWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOOkOOOO00KXNNWWWWWWWWWWNNXK00OOOOOOOKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdolc::::::::::::::::::::clodxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SOE is ERC721Creator {
    constructor() ERC721Creator("Shapes of Earth", "SOE") {}
}