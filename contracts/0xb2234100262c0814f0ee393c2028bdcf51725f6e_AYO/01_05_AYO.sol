// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Peon - Virtual Live Performance
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//    %%%%%###%######%%%###%%*=+#%%%%#*%%%%%%%%#%%%@@@@@@@@@%%%%%%%%%#++*#########**#%%%%###%@@@    //
//    %%%%##%%%####%%%##%%%*-=*%%%%*-=%%#%%%%%%%%%%%@@@@@@@@%%#%%%%%##*=++*******+##%%#**###%@@@    //
//    #%%%##%%##%%%%%##%%#==*#%%%#--#%%%%%%%@@@@@@@@@@@@@@@@%%#*#%####**+=+-::-++*###*+***%%%@@@    //
//    %*%%%#%%#%%%%%##%%*=+*%%%%*-+%%%%%%#%%%%@@@@@@@@@@@@@@%%#+==+##***=:--.-=--+******##%%%%%%    //
//    %#*%%#%*#%%@%%####*##%%%#+=#%%#+-=*#%%%%@@@@@%%%%%@@@%%%%+-=-+***+::--.-==--=+**==+****#%%    //
//    %%#%%##+%%@@%###**#%%##***#%#=-*%%%@@@@@@@@@@%%%%%%%%%%%%%=-+=**+-:....::==:++**+****#%%@@    //
//    #%%#%%**%%%%%##*####**##%%%#:=%%%@@@@@@@@@@@@@%%%%%%%%%%###--++*+:-....::==:=+*****##%%%%@    //
//    %#%#%%+*%%####*###*#%%%%%##==#%%@@@@@@@@@@@@@@%#**%%%%%%#+#*=-=++-::...::--:++*+==+***#%%%    //
//    %%%%#%+*#%#*####%%%%%%%%##*=#%%%%%@@@@@@@@@@@@@%%*+++#%%#+=**++===---:.::--+++**==++**####    //
//    @%#%##+*##%%##%%%@@%%%###*#%%%%%#%@@@@@@%#******%%#**=+#%#+-***+++===-:::=++++***#########    //
//    @%%#%#+*#*%%%%%@@%%%%####%%%@@%#*%%@@%#++=+#%#**+#*==*+=+##*=++*++++++===++++****###%%%%%%    //
//    @@%#%#*#####%%@%%%%#%%%%%%@@@%##*#%%#*###+***%#+%%%#+++===*+=-=====-=--+===+===++++##%%%%%    //
//    @@@%#%####*%%%%####%%%@@@%%%%%%###%###%#%**##%#*%%%##%#**=*-=-=:-::+:+---=---==-=**=#*%%%%    //
//    %%@%#%%##*%%%%#***%%@@@@@%###%%##%##%%%%#%%%%%%####*+=*#*#*##**********+++***++**##*#*%%#%    //
//    ##%%##%%##%%@%%#*%%@@@@@@%#####*%%#%%%@%%@%%%#%%%#***++=#%#**##****************#####%%%###    //
//    %##%%#%%##%%%%#+%%@@@@@@@%%###*%%#%%%%@%%@##%##%###****++*#%***#**************######%%%%%%    //
//    @%#%%##%%%%%%###%%@@@@@@@@%%#*%%%#%%%%%%%%%#%##%*#####*++*#%%%**#%%%%%%%###*+#####%%%%%%%%    //
//    @@%%%%%%%%%%%%%%%#%%%%@@@@@%%#%#%%%%%%@%%%%#%##%*###%##+##%#####**%%%%%%%%%*%%%%%%%%%%%%@@    //
//    %%%%%%%%%%%%%%%%**#**%@@@@@%%#%#%#%@%%@#%%%#%#%%##*###**##%#*%+%%##%%%%%%%%*##**#%%%%@@@@@    //
//    %%%%%%%%%%%%%%###***%%@@@@%%#%%#%#%@%%%#%@%%%**##****###++*#+%#*%%%%%%%%%%%%%##%%%@@@@@@@@    //
//    %%%%%%###########**#%@@@@@%%#%#%%%#%%%%#@%@%%#**#++*#%##*+*=**%*%%%%%%%%%%*#%%%%%%@@@@@@@@    //
//    %%%%%%%%%%%###*****%%%%%%%%%#%#%#%%%%%@%%%%%#%#*%***##%%#**=###%#%%%%%%%%%%##%%%%%@@@@@@@@    //
//    ########%%%####****%%%%%%%%%*%#%#%%%%#%%#@%@#%%#%###%%%%#*###%+%*#%%%%@%%%%%%%%%%%@@@@@@@@    //
//    ##########%##%#****%%%%%%%%%*#*%#%%%%%%%%@@@%%%%###%#%%%#*##=*+%#%%%%%@%%%%%%%%%%%@@@@@@@@    //
//    #######%%####%****#%%%%%%%%#*#*%##%#%%@%%#@@%#%%#%%%##****#*=#%%%%%%%@@%%%%%%%%%%%@@@@@@@@    //
//    ########%%%###++**%%%%%%%%%****%##%%%@@@@#%@%#@%%%%%%%#**++=#%%%%%%%%%@%%%%%%%%%%%%@@@@@@@    //
//    ####%%%#####%#****%%%%%%%%%+**#%%*%%%@@@@%@@%%@%%%@@%%%%%##=#%%%%%%%%%%%@%%%%%%%%%%@@@@@@@    //
//    %%##%%%%####%#****%%%%%%%%#+###%%#%%%@@%%%%@%%@%@@%@@%%%%#*+=-+*#%%%%%%%%%%%%%%%%%%%%%%%%%    //
//    %%%%%%%%%%%%#####%%%%%%%%%%*#**#+##%%@%%%%%%%%%%%%%%%%%##+**==-:::-==+*+*%%%%%%%%%%%%%%%%%    //
//    %%%%%%%%%%%%##%%%%%%%%#%%*++***%*#*#%%%%%%#%%######%%%%##+-#**+++*++***+=#%%%%%%%%%%%%%%%%    //
//    %%%%%%*%%%%%%%%%%%%%##*++*****###%%*%%##%%%####****#%@%###+=#***##*****+*%%#%%%%%#%%%%%%%%    //
//    %%##%%%%%%%%##%%###*++******######%%%%##############%%%####++##*###*##*+**#%#%##%%%%%%%%%%    //
//    %%%%%%*%%%##*#%%%*+++*****#########%%%%%########%%%%%%#%%%%#*#%%%####**#%##%%##*%%%##%%%%%    //
//    #%%%%%%%####%%%%%+*#################%%%%%%##%%%%%%%#%%%###%%%#########%%%%##*%%%%%%%%#%%%%    //
//    %%%%%%%###%%%%%%#+*##**#######%########%%%%%%%%%%#**##%%#*##########*#%%%#*#%%%%%%#*%%%%#%    //
//    %%%%%%%%%##%%%%%%+++#%#*#*####%%%%%######%%%%%%%#######%%%%#*#####%%%##%%#%%#%#%%%%##%%%%%    //
//    %%%%#%%%###%%%%%%#+**##%%%%#################%%%%#########%%%###%%%#%%#*##%%%#*##%%%%%##%%%    //
//    %%%%%%%%%%%%%#%%%%%########%%%%%%########################%%%#*%%%%%*%%###%%%%#*###%%%%%%%%    //
//    %%%%%%%%%%%%%#%%%%%%%%#*#####%%%%%%%%%%%%%%%%%%%%%######%%####*%%%%%*%%%#*#%%%%#*###%%%##%    //
//    *#%%%%%%%%%%%#%%%%@@@%@%%%%%##%%%%#%%%%%%%####%%%%%%%%%##**#%%##%%**#*%%%#*#%%%%#%%##%%%#%    //
//    %%%%%%**%%@@@%%%%%%%%%%%%%@@@@%%%%%%%%%%#%%%%%%%%%%%%%#***#%%###%%%*##*%%%#*#%%%%%%%##%%%%    //
//    %%%%%%#%%%%@@%%%%%%%%%%%%%%@@%%%%%@%%%%%%#%%%%%%%%%%%###%%%%%##%##%%*##*%%%#*#%%%%%%%%#%%%    //
//    %%%%%%%%%%%%@#%%%%##%%%%%%%@@@%%%%%@%%###%%%%%%%%%%%%%%%%**%%%%%##%%%*#**%%%#*#%%%%%#*##%%    //
//    @%%%@%%%%%%%@%%%%%%%%%%%%%%%@@%%%%%%@@@@@%%%%%%%%%%%%%%%%%#%%%%%##%%%%%%##%%%#**%%%%%###%%    //
//    @%%%%@%%%%%%@@%%%%%%@%%%%%%%%%%%%%%%%@@@@%%%%%@@%%%%%%%%%%%##%%%%##%%%%%%##%%#####%%%%##%%    //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract AYO is ERC721Creator {
    constructor() ERC721Creator("Peon - Virtual Live Performance", "AYO") {}
}