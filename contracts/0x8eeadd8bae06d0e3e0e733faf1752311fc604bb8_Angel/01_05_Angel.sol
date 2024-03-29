// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Malaika open editions.
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//    *#%%#%%%%%%%%#%%%#######*****++==-----------==++**####%%%%%%%@@@@@@@@@@@@@@@@@@@@@@@@@        //
//    #####*%%%%%%%#%#*######**#*+******+++++++++++++++++****#####%%%%%%%%%%%%@%@@%%@@@@@@@@@@@@    //
//    %%%%%%%%%%%%%%%%%%%%%##########************#####**++*++*****##*%%%%#%%%%#%##%######%%@@@%%    //
//    %%%%%#%%%%#%%%%%%%%##############***######%@@@%%###*++=+====++**%###@%%%%#*#+=======+%%%@%    //
//    %%%%%%%%%%%%%%%%##%###%%#################%@@@@#++*+++++**#++++*#*#%%%%@%*###***#####*%@@@@    //
//    %%%%%%%%%%%%%%%%%##%%%%%%%#######*=:..::-+#%#+::::::...-+*####%%%###########%%%#%##*+%@@@%    //
//    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#+-:.::-==++**+=:.....::.:+*###########**###%%%@%%%%**+%@@@@    //
//    %%%%%%%%%%%%%%%%%%%%%%%%%%%%#*=-:...:-=**#%#*+-:...:-==-+*%%##**###==-=+#%%%%%%%%#**+%%@@@    //
//    %%%%%%%%%%%%%%%%%%%%%%%%%%%*++=-:...:-+*#%%##+-:.::==+**+++++**##*+==+==*#%#%%%%%@%=+%@@@@    //
//    %%%%%%%%%%%%%%%%%%%%%%%%%%+-==--::.:-=+*#%%#*=:..:-+**##*+===+*###*#*+++###%%####@%=+%%%@@    //
//    %%%%%%%%%%%%%%%%%%%%%%%%%#-=+=+---+**###%%%#*+=--=++++*##*==-=**######****###*###%#++%%@@%    //
//    %%%%%%%%%%%%%%%%%%%%%%%%%****#+=#%%%%%%%%%%%%%##*+++++++++*=+*+*######======+++*%@###%@@@%    //
//    %%%%%%%%%%%%%%%%%%%%%%%%%#***++%%%%%%%########%%%#**+===++*****######*+=======:=#%@%#@@@@@    //
//    %%%%%%%%%%%%@%%@@%%%%%%%*++++#%%%%%%#####***###%%%#*+===+**==**####*+==-*##*+=+*%%++*@@@@@    //
//    %%%%%%%@@@@%%%%%%@%%@@@*===+*%%%%%%%####****###%%%%#*++==+***#####**-==-*##******[email protected]@@@%    //
//    @%%%@@@@%%%%@@%%%%%%%%%=-:+*#%%%%%%%%%%######%%%%%%%%**++++#****#***+==+##*****#*---+%%%@%    //
//    %%%%%%%%%%%%%%%%%%%%%%%+==**%%%%%%%%%%%%%%%%%@@%%%%%%%**#####++********###*******++==%%%%%    //
//    %%%%%%%%%@@@@%%%%%%%%%@%#**%%%%%%%%%%%%%%%%%%%%%%%%%%#%%%#++===++=++++++*#*++++**#*=+%@@@%    //
//    %%%%%%%%@@@@@@@@%%%%@@@@@%%#%%##*#*##%%%%#*#*#####%%%#%%%=..::-==----=====+**#*##%*[email protected]@@@%    //
//    @%%%%%@@@@@@@@@@@@@@@@@@@@@%%%%####*#%##%#**###**#%%%%%#+... ..-:::::----=+*==*###**[email protected]@@@@    //
//    %%%%%%%@@@@@@%@@@@@@@@@@@@@@@%%%#####%%%%#####**#%%%%##+. . ...-:::.::::---+*==#*%#[email protected]@@@%    //
//    %@%%%%@@@@@@@@@@@@@@@@@@@@@@%@%%%###%%#%%######%%%@@++-.  .....::::---------++=#%@%[email protected]@@@%    //
//    @%%%%%%%%%%@@@%%@@@@%%%%@@@%%@@%%%%%%%%%%%###%%%%%@# ..  .....:==-====-------+-**%%++%%%%%    //
//    %%%%%%%%%%@@@@%%%@@@%@@@@@%%%%%@@@%%@@@@@@%%%%%%%%%-     ....:-=-=-:-::::::::+=*#@#**@@@%%    //
//    %%%%%%%%%@@@@@@@%%%%@@@@@@@@%%%%%@@@@@@@@@@@%%%%%%+      .:-:..::..:-......-***#*%@%%@@@@%    //
//    @@@@%%@@@@@@@@@@@@@@@@@@@@@@@%%*+%@@@@@@@@%%%%%@@%:         .................-+#%@###@@%%%    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#**##%%%%#%%%%@@@@@@=         . ................:+%#***%%%%%    //
//    @@@@@@@@@@@@@@%%@@@@@@@@@@@@@@*-##*%@@%@@@@@@@@%**%+=:----==+*=#%##*%%##**==+=====+++%%%%%    //
//    @%%%@@@@@@@@@@%%%%%%%%%%%@%%%#=%++#@@@%%%@@@@@%#+-***=+++====+*+##%%@@@%%%%%***+*+++*%%%%%    //
//    %%%%%%%%%%%@@%%%%%%%%%%%%%%%#+#**%%@@%+*%#%@+***++****##%%%%##%%%%%%%%%%%%%%%%%%%%%%%%%%%%    //
//    %%%%%%%%%@@@@%%%%%%%%%%@@%%#+*#+++#*#+=*%%+%@@@%%*+++##**#%%@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%    //
//    @%%%%%%@@@@@@%@@%%%%%@%#%#=*++*%*++=+*####%%@@@#*%#*#**%%##%%%%@@%%%%%%%%%%%%%%%%%%%%%%%%%    //
//    @@@@@@@@@@@@@%@@@@@@#**%*++++*%##*++-*%%##%@%#++**+*##%%##*++*#%%@@%%%%%%%%%%%%%%%%%%%%%%%    //
//    %%%@@%%%@@@@@%%%@@%++***+++*#+*%#**##%%%%%*+##*=***##*+===++++==+#%@@%%%%%%%%%%%%%%%%%%%%%    //
//    @@%%%%%%%%%%@%%%%%+**+++++#%%#%@@%%%%###%%#=*%***#*+=-=+++==----==+*%%%%%%%%%%%%%%%%%%%%%%    //
//    %%%%%%%%%%%%%%%%%###**++*%@%%=*#%%%#+#%##%%******==-+++=--------===+*%%%%%%%%%%%%%%%%%%%%%    //
//    %%%%%%%%%%%%%%%%%*##=*+*#%%@%%#%%##****#%%%#*#*=--+*+=----------====++#%%%%%%%%%%%%%%%%%%%    //
//    %%%%%%%%%%%@%%%@%+#=*+***%*####%%%#*####*#%%*=--+*+=-------------====++%%%%%%%%%%%%%%%%%%%    //
//    @%%%%%%%%@@@@@@@#*+*+#*#-*+##*#%%#%#%%#**##+=-=**=---------------=====+*%%%%%%%%%%%%%%@%@@    //
//    %@%@%%%@%%%%%%%%*=#+*+***####%%@%%%#=-+*#*=--+*+=-----------------====++*%%@%%%%%%%%@%%%%%    //
//    %%%%%%%%%%%%%%%%+++***###@%#*%@%@%#**#**+=--+*+-------------------====+++*%%%%%%%%@%%%%%%%    //
//    %%%%%%%%%%%%%%%#=*+#*%@@%%@%%##*%##%%##+=--+*+--------------------=====+++*%%%%%%%%%%%%%%%    //
//    %%%%%%%%%%%%%%%**+*##%@###*##**-*#%%%#+=--+*+=--------------------=====++++*%%%%%%%%%%%%%%    //
//    %%%%%%%%%%%%%%%=*+##%%%%#+=+*****#@@#+=--=**=--------------------======+++=+*%%%%%%%%%%%%%    //
//    %%%%%%%%%%%%%%%+*+%##%####**##*++%@#*+--=**+=--------------------===========+%%%%%%%%%%%      //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract Angel is ERC721Creator {
    constructor() ERC721Creator("Malaika open editions.", "Angel") {}
}