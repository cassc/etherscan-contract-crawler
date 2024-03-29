// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NDROID
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::    //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::    //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::    //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::    //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::    //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::    //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::    //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::    //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::    //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::    //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::    //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::    //
//    :::::::::::::::-==:::-:::--::::::--:::-:::=+-:::::::::::::::    //
//    ::::::::::::::::-====*=-:=#=::::=#+:-=*=====::::::::::::::::    //
//    ::::::::::::::::--:-=+#*+#%%%**#%%#**#++-:--::::::::::::::::    //
//    :::::::::::::::::=++%=*#%@%%@##@%%@%#*+%++=:::::::::::::::::    //
//    ::::::::::::::::::=====%@@@@*%@[email protected]@@@@+=++=-:::::::::::::::::    //
//    :::::::::::::::::::==-+*##%**%%#*%%%#*===-::::::::::::::::::    //
//    ::::::::::::::::::-=+#*%@@[email protected]@%*%+--::::::::::::::::::    //
//    ::::::::::::::::::+#@@*#++---===-=*+#*@@#+::::::::::::::::::    //
//    ::::::::::::::::::-*@%*+------:-----+*%@*-::::::::::::::::::    //
//    ::::::::::::::::::@#---==*=-=++=-=*+--=-*@::::::::::::::::::    //
//    ::::::::::::::::::#@:::--=--=--=-==--:::%#::::::::::::::::::    //
//    :::::::::::::::::::-::::::--------::::::-:::::::::::::::::::    //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::    //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::    //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::    //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::    //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::    //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::    //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::    //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::    //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::    //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::    //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::    //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::    //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::    //
//                                                                    //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract NDRD is ERC721Creator {
    constructor() ERC721Creator("NDROID", "NDRD") {}
}