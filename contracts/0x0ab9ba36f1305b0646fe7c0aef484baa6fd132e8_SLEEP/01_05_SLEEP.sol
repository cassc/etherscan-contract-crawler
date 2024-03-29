// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: An Unconscious Dialogue
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                           //
//                                                                                                           //
//       ##    ##   ##                                                                                       //
//      ####   ###  ##                                                                                       //
//      ####   #### ##                                                                                       //
//     ##  ##  ## ####                                                                                       //
//     ######  ##  ###                                                                                       //
//    ##    ## ##   ##                                                                                       //
//    ##    ## ##   ##                                                                                       //
//                                                                                                           //
//     ##  ##  ##   ##    ####     ###    ##   ##   #####     ####    ######    ###     ##  ##   #####       //
//     ##  ##  ###  ##   ##  ##   ## ##   ###  ##  ##   ##   ##  ##     ##     ## ##    ##  ##  ##   ##      //
//     ##  ##  #### ##  ##       ##   ##  #### ##  ###      ##          ##    ##   ##   ##  ##  ###          //
//     ##  ##  ## ####  ##       ##   ##  ## ####    ###    ##          ##    ##   ##   ##  ##    ###        //
//     ##  ##  ##  ###  ##       ##   ##  ##  ###      ###  ##          ##    ##   ##   ##  ##      ###      //
//     ##  ##  ##   ##   ##  ##   ## ##   ##   ##  ##   ##   ##  ##     ##     ## ##    ##  ##  ##   ##      //
//      #####  ##   ##    ####     ###    ##   ##   #####     ####    ######    ###      #####   #####       //
//                                                                                                           //
//    #####     ######     ##    ####       ###      ####    ##  ##  #######                                 //
//     ## ##      ##      ####    ##       ## ##    ##  ##   ##  ##   ##  ##                                 //
//     ##  ##     ##      ####    ##      ##   ##  ##        ##  ##   ##                                     //
//     ##  ##     ##     ##  ##   ##      ##   ##  ##  ###   ##  ##   ####                                   //
//     ##  ##     ##     ######   ##   #  ##   ##  ##   ##   ##  ##   ##                                     //
//     ## ##      ##    ##    ##  ##  ##   ## ##    ##  ##   ##  ##   ##  ##                                 //
//    #####     ######  ##    ## #######    ###      #####    #####  #######                                 //
//                                                                                                           //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             //
//    @@@@@@@@@@@@@@@@@@@@@@%%%%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%@@@@@@@             //
//    @@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%@@@@             //
//    @@@@@@@@@@@@@@@@@@%%%%%########%%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%@@%%%%%%%%%%%%%%             //
//    @@@@@@@@@@@@@@@@@%%%%%#############%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%%%%%%%             //
//    @@@@@@@@@@@@@@@%%%%%%####******######%%%%@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%%%%%%%%%             //
//    @@@@@@@@@@@@@@%%%%%%%###***********####%%%%%@@@@@@@@@@%#%@@@@@@@@@%%%%%%%%%%%%%%%%%%%%%%%%             //
//    @@@@@@@@@@@@@%%%%%%%####*************#####%%@@@@@@@@@@@@##%@@@@@@@%%%%%%%%%%%%%%%%%%%%%%%%             //
//    @@@@@@@@@@@@%%%%%%%%###****++++*********##*%%@@@@@@@@@@@@%*%@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%             //
//    @@@@@@@@@@@@%%%%%%%####***++++++*******##*+*%%@@@@@@@@@@@@%*%@@@@%%%%%%%%%%%%%%%%%%%%%%%%%             //
//    @@@@@@@@@@@@%%%%%%%####***++++++*******#%++=#%%@@@@@@@@@@@@%##%@%%%%%%%%%%%%%%%%%%%%%%%%%%             //
//    @@%%%%%%@@%%%%%%%%%%###**+++++++*****++*#=::+#%%@@@@@@@@@@@@%*#%%%%%%%%%%%%%%%%%%%%%%%%%%%             //
//    @@@%%%%%%%%%%%%%%%%%###**+++++++*****+=+*+:.-+#%%@@@@@@@@@@@%*=*%%%%%%%%%%%%%########%%%##             //
//    @@@@@@@%%%%%%%%%%%%####***+++++*******==++=---+#%%@@@@@@@@@@@@%*=+**#%%%%%%%##############             //
//    @@@@@@@@@@%%%%%##%%####****************++=++=****##%@@@@@@@@@@@%#+=+#%####%###############             //
//    @@@@@@@@@@%#############*****************+**=*###***#%@@@@@@@@@@@@%%#+####################             //
//    @@@@@@@@@@%##*###########************##*****#++%%%#**%%%%%@@@%%@@@@%*::=##################             //
//    @@@@@@@@@@%######%%########********######**####-*%%**##%##%@%*=+%@@@@#+==*################             //
//    @@%%%@@@@%%****##%%%#####################***#####%%%***###%%#*+==#@@@@@%#**###############             //
//    %%%%%%@@@%#++++*###%#####################****#####+#+*===+=++#*::+#%@@@@@%##%%%%%%%%%%%%%%             //
//    %%%%%%@@@%*====+*###%#####################***####+-=:::--::-+**+::+*%@@@@@@%#%%%%%@%@%%%%@             //
//    %%%%%%@@@%+-::-=+*##%%%%%#%######################*=::..::.:::-=+=-:=*#@@@@@@%%%%%%%@@%@@@@             //
//    %%%%%%@@%#-:...:=+*##%%%%%%%%%%%%################*=:.....:..:::-+++++**%%@@@@@%%%%%%@@@@@@             //
//    %###%%%%%*:....:-+*##%%%%%%%%%%%%%%%%%%%%%#%###%%#*=..:.:::::::::-*%%#**%%@@@@@%%%%@@@@@@@             //
//    ####%%%%%=..  .:-=*##%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#+-.:..:---::-=+#%%%%**#%@@@@@%%@@@@@@@@             //
//    #*###%%%#-.    .:-+*#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#=:::::=+==--=+*##%#%#*#%%@@@@@%@@@@@@@             //
//    ****#%%%+:     .:-+*#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#+-:.::-+*+--=+*##%#%%%##%@@@@@@@@@@@@@             //
//    +++*#%%#+.     .:-+##%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#=::::-+*#+==+*#%%%%%%%%%%@@@@@@@@@@@@             //
//    ==+*#%%#-.     ..:=*#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#*-:::-=+**++*##%%%%%%%@%%%@@@@@@@@@@@             //
//    -=+*#%%*:       .:=*#%%%%%%%%%%%%%%%%%%%%%%%%%########+---=+***===*##%%%%%%@@%%%@@@@@@@@@@             //
//    --=*###+.       .:=*#%%%%%%%%%%%%%%%%%#####%%####******+++**####***##%%%%%%%%@@%%@@@@@@@@@             //
//    :-=+*##+.       .:=*#%%%%%%%@@%%%%%%%#***##%#######******######%%##%%%%%%@@%@%@@@@@@@@@@@@             //
//    :-=+*##-        .:=*#%%%%%%@@@@%%%%%#*+++*#***#%%%%%%%#########%%%%%%%%%%@@@@@@@@@@@@@@@@@             //
//    :-=+##*:        .:=*#%%%%%%@@@@@%%%#*+++*#*++*#%%%%%%%%%%%%%%%%%%%%%%%%%@@@@@%@@%@@@@@@@@@             //
//    .:=+*#+.        .:+*#%%%%%%@@@@@%%#**++*##+++*#%@@@@@@@@%%%%%%%%%%%%%%%%@@@@@@@@%%@@@@@@@@             //
//    .:=+**=.       ..:+*#%%%%%%@@@@%#**++*###*+**#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%@@@@@@@@@             //
//    .:=+**-        ..-+##%%%%%%@@@%*++++*##****##%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%@@@@             //
//    :-=+*+:        .:=*##%%%%%@@@#+=--=*#*++*##%@@@@@@@@@@%%###%%%@@@@@@@@@@@@@@@@@@@@@@%%@@@@             //
//    :=++*+:        .:=*##%%%%@@%*=:::-**+++*#%%@@@@@@@%%%#*+=--=+#%%@@@@@@@@@@@@@@@@@@@%%%@@@@             //
//    -=++*+.        :-+*#%%%%@@%+-:..-++==+*#%@@@@@@@@%%##*+=:::-=*#%%@@@@@@@@@@@@@@@@@%%%@@@@@             //
//    -=+**=.       .:=+*#%%%@@%*=:..-++==+*#%@@@@@@@@@%%####*+++*##%%%@@@@@@@@@@@@@@@@%%%%@@@@@             //
//    -=+++-.       .-+*#%%@@@#*=-:-+++==+*%@@@@@@@@@%%%%%%%%%%%%%%@@@@@@@@@@@@@@@@@@@%%%%@@@@@@             //
//    -++++:       .-+*#%%@@%#+=--=*+==+*#%@@@@@@@%%#####%%@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%@@@@@@             //
//    =+++=:.    .:=+#%%@@@%*+===+*++++*%@@@@@@%##*++++*##%%@@@@@@@@@@@@@@@@@@@@@%%%%%%%%@@@@@@@             //
//    ====-:....:-+#%%%@@%#*+===**++**#%@@@@@%*+=----==+*##%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             //
//    ==-=--::-=+#%%%@@%#*+===+****##%@@@@@%#+=:..:--==++*##%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             //
//    =======+*#%%@@@@%#++===+***##%@@@@@@@#*=:..:--===++**#%%%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             //
//    ++****#%%%@@@@%%*+====+**##%%@@@@@@@%#*=---===+++++**##%%%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             //
//    *###%%%@@@@@@%#++==-=***#%%@@@@@@@@@%%#************###%%%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             //
//    %%%%@@@@@@%%#*+==-=+**#%%@@@@@@@@@@@%%%%%%%%%%%%%%%%%%%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             //
//    %@@@@@@@%%#*+==--=*##%%@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             //
//    @@@@@@%%#*=--::=*##%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             //
//    @@@@%%#*=-:..-+##%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             //
//    @@@%%#*-:...-*#%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             //
//    @@%%#+-. ..=*#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             //
//    @%%#+-:..:+*%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             //
//    %%#+=-:-=*#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             //
//    %#*+==+*#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             //
//    %######%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             //
//    %%%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             //
//    %@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             //
//                                                                                                           //
//                                                                                                           //
//                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SLEEP is ERC721Creator {
    constructor() ERC721Creator("An Unconscious Dialogue", "SLEEP") {}
}