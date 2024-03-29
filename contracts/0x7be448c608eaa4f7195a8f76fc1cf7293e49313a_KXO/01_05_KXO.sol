// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KING XEROX 1/1s
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//       .   ..:...:--..     .::. ..:-:.. ....          . ...:::=:.      .......          //
//     . ++++=+=+=+++=+++=======++++*+*+*+++++==+++=======++=++=*+*+===+++++++++===:      //
//      .+=====+=====+=+==++++++******+*##+++****++++++++**+++++***+++=*+++++==+==+.      //
//      :=+=++=++++===+++*********************************#******+++**+++-..    .::.      //
//       . ....-=+=---=+********************************************#++++=::...---=.      //
//        =:-+:..-=++++******************************************##**+====----==---:      //
//      ..=:.=-:--------====++++++++++************************########*++==-::..::-:      //
//       .----::-++**+++++++++======---=========+++++++++====+++=+**#++=-:------=--:      //
//       :-::---=+*****#*###%%%%@@@%%%*++++++++++++++++++****+++**#%#*++***++++++==-      //
//      .=++====+**#***###%%@@#:*@@@@@@%**********%%@@@@+#%%%%#*************+*=:-+=-      //
//      .=--:.--+******#%@@@@#-#::#@@@@@*********#@@@@%:  -@@%%#%***********+-:..:-:      //
//       ====:.:.+*****%%@@@@--@@# -@@@%***##**#*%@@@%: +. *@@@%#************++. .-       //
//     : ===:::-+******##@@@+.#@@@# .%@%**#@@#***%@@%: =@+ :@@@@%###*********==-::-  .    //
//     .  .:-==-+*****##@@@@-.====+**%@@*#@@@%**#@@#. +@@@::+@@@%***#********+=--:.       //
//    .: .==-:--:.+*****%@@@@@@@@@%%#%###@@@@%#*%@@%*++++==:=%@@#****#*******++=:  ..     //
//     ..--:-:...:*****####%%@@@%#*****#%@@@@@%##%%%@@@@@@@@@@@%*************=--=+-..     //
//      .==+=--=++*****######*#**********#%%%%#**#*######%%%%%@%**********#**: :=: .:     //
//      .=====-:-+++**********************#********#####*###****#***********+-.-+- .      //
//      :==-::::::-=+**********###******##**********#***##*###**#**********=.: .:: .      //
//      .-=-=====-.-==+******##%@@@@%####***######*******#*####***********+=:::::. .      //
//      :+++=--===-=++++****%%%%%*##%@%%%%%%%@@@%%####******###*********+++====--: :      //
//      ++++=---::=====++#%@@#*@@**#%@###%@###@%**#@%##%#***#*********+=++===+---: -      //
//     .+++===+=====+++++*%@@%#%@#*#@@%##%@##%@%**%%*%%#%%*********++========----:.-      //
//     .=+=:.-+=====+++++*#@@@%#@@##@@@@%@@%#%@@##@%#@@%@@#******+===========: :=.        //
//      ==.  ==++++=++++=*%@@@@@@@@@@@@@@@@@@@@@@@@@%@@@@@@##*+===========+==-  =-        //
//      ========+*+=+*#*++#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%*======+==+=====+=  :=        //
//      ====+===+*+=**+*#+%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#*+**++*++++=++=+=  ....      //
//      =+=++*++******+**+#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%*+++**++=++=+=+==++=-..     //
//      ==++++******++=++*%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%#*****+=+**+==+====+==::.    //
//      -=+==++++===+++***%@@@@%@@@@@@@@@@@@@@@@@@@@@@@@@@#*+==++++++**--=++--:::::  .    //
//     .=*++***+**********#@@#%#%@@##@@@@@@@@@@@%@@@@@%@@%*******++++++****+#+++=++..-    //
//     -+******************%%%@%#@%##@@%#@%##@@##@@%@%#@@%*******************++**++. .    //
//     -******************+==+#%%@%#*%%#*%%##@%##@%%@##%@#*********#********+***++=.      //
//     :****************+===+***#%%%%@#%#%#%%@%#%@%@@%%#+=+********************+++*.      //
//    .=***************====*******#%@@@%@@@@@@@@@@@@%%#**===**********************+:.     //
//    **************#+===+***********%@@%%%%@@@@%%###*****+==+*******************+*+      //
//    **************+==+**************#@@#**#%#%%###********+==+************#******:::    //
//    ****************************************%%#*#**#*##***************************+.    //
//    *************************#************************###************************+      //
//    ************************************************##**#********************#*#**:     //
//                                                                                        //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract KXO is ERC721Creator {
    constructor() ERC721Creator("KING XEROX 1/1s", "KXO") {}
}