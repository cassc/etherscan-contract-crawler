// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Camp DAO
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    MWNXXXNNNNWWWWWNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNWNNNNNNNNWNNXXXNWM    //
//    WNNNK0kxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkOKNNNN    //
//    XNKd:,'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''',:dKNX    //
//    NKl,'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''',lKN    //
//    Wk;'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''';kW    //
//    Wk;'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''';kW    //
//    Wk;'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''';kW    //
//    Wk;'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''';kW    //
//    Wk;'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''';kW    //
//    Wk;'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''';kW    //
//    Wk;'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''';kW    //
//    Wk;''''''''''''''''''';oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxl,''''''''''''''''''';kW    //
//    Wk;''''''''''''''''''':0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk;''''''''''''''''''';kW    //
//    Wk;''''''''''''''''''':0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk,''''''''''''''''''';kW    //
//    Wk;''''''''''''''''''':kNNNNNNNNNNNNWMMMMMMMWNNNNNNNNWMMMMMMMMMWNNNNNNNNNNNXx,''''''''''''''''''';kW    //
//    Wk;''''''''''''''''''',:cccccccccccxNMMMMMMKdccccccccdXMMMMMMMMKoccccccccccc;,''''''''''''''''''';kW    //
//    Wk;'''''''''''''''''''''''''''''''c0WMMMMMXd,'''''''',oNMMMMMMMNx;''''''''''''''''''''''''''''''';kW    //
//    Wk;'''''''''''''''''''''''''''''':kWMMMMMNx;'''''''''';xNMMMMMMMXd,'''''''''''''''''''''''''''''';kW    //
//    Wk;''''''''''''''''''''''''''''';xNMMMMMWk;'''''''''''';kWMMMMMMMKl,''''''''''''''''''''''''''''';kW    //
//    Wk;'''''''''''''''''''''''''''',dNMMMMMW0c''''''''''''''c0WMMMMMMW0c''''''''''''''''''''''''''''';kW    //
//    Wk;''''''''''''''''''''''''''',lKMMMMMMKl,'''''''''''''',lKMMMMMMMWO:'''''''''''''''''''''''''''';kW    //
//    Wk;'''''''''''''''''''''''''''c0WMMMMMXo,'''''''''''''''',oXMMMMMMMNx;''''''''''''''''''''''''''';kW    //
//    Wk;'''''''''''''''''''''''''':OWMMMMMNx;'''''''''''''''''',xNMMMMMMMNd,'''''''''''''''''''''''''';kW    //
//    Wk;''''''''''''''''''''''''';xNMMMMMWk;'''''''''''''''''''';kWMMMMMMMXl,''''''''''''''''''''''''';kW    //
//    Wk;''''',:cclcccccccccccccllxNMMMMMMXdccccccccccccccccccccccdXMMMMMMMMKocccccccccccccccccc:,''''';kW    //
//    Wk;'''''c0WWWWWWWWWWWWWWWWWWWMMMMMMMWWWWWWWWWWWWWWWWWWWWWWWWWWMMMMMMMMMWWWWWWWWWWWWWWWWWWNk;''''';kW    //
//    Wk;'''''cKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO;''''';kW    //
//    Wk;'''''cKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO;''''';kW    //
//    Wk;''''';oxxxxxxxxxxxxxxkXMMMMMMMNOxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxKWMMMMMMWKxxxxxxxxxxxxxxxl,''''';kW    //
//    Wk;'''''''''''''''''''',dNMMMMMMWk;''''''''''''''''''''''''''''',cKMMMMMMWKc''''''''''''''''''''';kW    //
//    Wk;''''''''''''''''''',oXMMMMMMWO:''''''''''''''''''''''''''''''',oXMMMMMMWO:'''''''''''''''''''';kW    //
//    Wk;'''''''''''''''''',cKMMMMMMMKc''''''''''''''''''''''''''''''''',dNMMMMMMWk;''''''''''''''''''';kW    //
//    Wk;'''''''''''''''''':OWMMMMMMXo,'''''''''''''''''''''''''''''''''';xWMMMMMMNd;'''''''''''''''''';kW    //
//    Wk;''''''''''''''''';kWMMMMMMNd,'''''''''''''''''''''''''''''''''''':OWMMMMMMXo,''''''''''''''''';kW    //
//    Wk;'''''''''''''''',dNMMMMMMWk;''''''''''''''''''''''''''''''''''''''c0MMMMMMMKl,'''''''''''''''';kW    //
//    Wk;''''''''''''''',oXMMMMMMWO:''''''''''''''''''''''''''''''''''''''',lXMMMMMMW0:'''''''''''''''';kW    //
//    Wk;'''''''''''''',lKMMMMMMM0c''''''''''''''''''''''''''''''''''''''''',dNMMMMMMWk;''''''''''''''';kW    //
//    Wk;'''''''''''''':0WMMMMMMXl,'''''''''''''''''''''''''''''''''''''''''';xNMMMMMMNx;'''''''''''''';kW    //
//    Wk;''''''''''''';kWMMMMMMNd,'''''''''''''''''''''''''''''''''''''''''''':kWMMMMMMXo,''''''''''''';kW    //
//    Wk;'''''''''''',lOKKKKKK0d;'''''''''''''''''''''''''''''''''''''''''''''':kKKKKKKKk:''''''''''''';kW    //
//    Wk;''''''''''''',;;;;;;;;,'''''''''''''''''''''''''''''''''''''''''''''''',;;;;;;;,,''''''''''''';kW    //
//    Wk;'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''';kW    //
//    Wk;'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''';kW    //
//    Wk;'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''';kW    //
//    Wk;'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''';kW    //
//    Wk;'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''';kW    //
//    Wk;'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''';kW    //
//    WKl,'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''',lKN    //
//    XNKd:,'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''',:dKNX    //
//    WNNNKOkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxk0KNNNW    //
//    MWNXXXNNNNNWWNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNNNNNNNNXXXNWM    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DAO is ERC1155Creator {
    constructor() ERC1155Creator("Camp DAO", "DAO") {}
}