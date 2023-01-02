// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Johnny Dollar Limited Editions V2
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//                                                                          //
//    Preview                                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMWk;,lxXMMMMMNx:kWW0ONMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMW0o'..lKMMMMM0' oNk.,0MMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMNKOxxkkKWMNXKxo:. .;. .ckKNWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWKkooxOXWMWXOol:'.          .':d0NMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWKx:.,xXWMMMKdc:ccclll' .lc. .,..  .,lONMMMMMMMMMM    //
//    MMMMMMMMMMMMMW0dccl, .OMMMWOccdOKXNWMWo '0K, lNX0xl;.  ,dKWMMMMMMM    //
//    MMMMMMMMMMW0dccoONWx. oWMM0,;KMMMMMMMWd..OX: :XMMMMWKo.  .c0WMMMMM    //
//    MMMMMMMWXOdloONMMMMK; ;KMWo.lNMMMMMMMMk..kNl ,KMMMMMMWO'   .c0WMMM    //
//    MMMMWX0kdd0NMMMMMMMWo .kMX: 'kWMMMMMMMO..dWo '0MMMMMMMWd.   'kWMMM    //
//    MMW0l;lldXMMMMMMMMMMO. lNWd. .l0WMMMMM0' oWx..kMMMMMMMM0;,lkXWMMMM    //
//    MMXo.  'kMMMMMMMMMMMX; ,KMWO;. .:oxXWMK; cNO..dWMMMMMMMWNWMMMMMMMM    //
//    MMMW0do0WMMMMMMMMMMMWo .xMMMNOc.   .:xk; :X0' oWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMO. lNMMMMWXkdc'  .  ,0K; cNMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMX: ,KMMMMMMMMMNOo;.  ':. ;XMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWo .kMMMMMMMMMMMMNo. .   .l0NMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMO. lNMMMMMMMMMMMMk..ok;   .,lONMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMX; ;KMMMMMMMMMMMMO..dWk. ,;.  'lOXWMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWo .OMMMMMMMMMMMM0, oW0' oNKd:.  'lONMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMk. oWMMMMMMMMMMMX; cNK, cNMMWKx;. .;xXMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMK, cNMMMMMMMMMMMNc :XX: :XMMMMMW0o'  'dXMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMNc ,KMMMMMMMMMMMWl ,KNl ,KMMMMMMMMXd'  :KMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMWd .OMMMMMMMMMMMWd '0Wd .OMMMMMMMMMMXc  lNM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMk..xMMMMMMMMMMMMx..OMx..kMMMMMMMMMMMK; '0M    //
//    MMMMW0odXMMMMMMMMMMMMMMM0' oWMMMMMMMMMMMk..xMO..dWMMMMMMMMMMWd..dW    //
//    MMMMXc  oWMMMMMMMMMMMMMMK, lNMWWMMMMMMMM0' dW0' lWMMMMMMMMMMMk. lN    //
//    MMMMM0, .kWMMMMMMMMMMMMMX; oNKl;lx0WMMMMK, lWX; cNMMMMMMMMMMWo  lN    //
//    MMMMMWx. 'OWMMMMMMMMMMMMK;.dWO;   .;dKWMX; cNNc ;KMMMMMMMMMW0o..kM    //
//    MMMMMMNo. .oKWMMMMMMMMNKo..kMMNx,.   .;dk; ;XWo '0MMMMMMWX00KklkWM    //
//    MMMMMMMNo.  .cdO00Okxdxk:'xNMMMMNKk:.   .  .xXd..kMWX0kxxxkOO0XWMM    //
//    MMMMMMMMNx'     .,clxOKOx0WMMMMMMMMWKd:.    ...  ';,...':oxOXWMMMM    //
//    MMMMMMMMMWKo,.   ';:lokKWMMMMMMMMMMMMMWXOc  .'.  .',;cox0XWMMMMMMM    //
//    MMMMMMMMMMMMN0kdoodx0NWMMMMMMMMMMMMMMMMMMO,:0N0:;kNWWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXOXMMNKXMMMMMMMMMMMMMMMMM    //
//                                                                          //
//                                                                          //
//                                                                          //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////


contract JohnnyDollar is ERC1155Creator {
    constructor() ERC1155Creator("Johnny Dollar Limited Editions V2", "JohnnyDollar") {}
}