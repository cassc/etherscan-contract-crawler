// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MEIOS_EX
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                      :=***+--:---*********=--:---**=-:                                     //
//                                  .=#@@@@@%####%@@@@@@@@@@@#@@@[email protected]=%@:@@+#+-                                 //
//                               :[email protected]*%@####[email protected]@@@@@@@@@@@@@@%%@%@@*@%:@*[email protected]*[email protected]@*+:                              //
//                             [email protected]@[email protected]###@@-------*@@@@@@@=%*[email protected]@**@@@@@[email protected]@:@@[email protected]%*:                            //
//                           :- [email protected]@@%#=    -%%#*==+*%%+-=*#%@#=*@@@@@%*%@[email protected]+*@+-                          //
//                         :%. .    +=-.  .-++-: :=*@@@@@@@%*+:. :=*@@#+=#%[email protected]#@#*##:                        //
//                        [email protected]*+=:       :++=. .=#@@@@@@@@@@@@@@@@@*-  .=#@%*#=*@*@@@%%*:                       //
//                       *@*: .:-=: -==- .-*%@@@%#*+-:.   .:-+*#%@@@%*=: -+%*###*%#.:=%*.                     //
//                      #@##@[email protected]@@=++:  =#@@%*=:                   -=*%@@%+: :+%@@@@[email protected]+ -#.                    //
//                     #%#@%+#@@*:  :*@@*-                            .-*@@%=. -#@@#[email protected]@*=*                    //
//                    :#+#*[email protected]@+.  =%@*-                                   [email protected]@#: [email protected]@=%*+#=                   //
//                    #@**#%=  .+%+--+#@@@@#+:                     -+%@@@%%+--+%#=  -#*+*@%                   //
//                    @@@%:   *%-.*@@@@%+:   :+                  .+.   :[email protected]@@@@*.-%@=  [email protected]@@@                   //
//                    =##   =%= [email protected]@@@@=       .+                 +        [email protected]@@@@- [email protected]%:  *##                   //
//                .:...+: :%+ .#@@@@=          *                 +          =%@@@#. *@= :+:.:.:               //
//              -:  :::=#@@+  %@@@#            #                 +            #@@@%  *@@#=:::  :-             //
//             -  ++. -#@@@- [email protected]@@*             %                 *             #@@@+ [email protected]@@#- :++  -            //
//             -  %. *@@@@@. @@@%             *:                 -=            [email protected]@@@ [email protected]@@@@* .%  +            //
//             =.  +=#@@@@@. @@@-            +-                   *-            [email protected]@@ :@@@@@*==  .-            //
//              :.   *@@%@@- #@@:           +=                     =+           [email protected]@% [email protected]@%@@#   .:             //
//               +*:    #@@% .%@+         =*:                       :*=         *@%. %@@%    -*=              //
//               ##@@%##@@@@*  =%-    .-==.                           .==-.    [email protected]=  *@@@@##%@@##.             //
//                *@@@@@@@@@@=  .:--=--...                             ..:--=--:   [email protected]@@@@@@@@@*               //
//               =%%@@@@@@@@@@#:.---:==-::--==:                   -=+--:--==:--: .#@@@@@@@@@@@@*              //
//                 [email protected]@*@@@@@@@@@@@%*=:.       -+*+:.         .:=+=:       .:=*%@@@@@@@@@@@#@@:                //
//                 .: [email protected]@@@@@@@#+=+*@@@%+.       =#%        :@#=       [email protected]@@@*+=+#@@@@@@@@: :                 //
//                     %@@@@@@=     #@+:*@#-      .%.       :#       -#@+:[email protected]%     [email protected]@@@@@%                    //
//                      ..*%@@#==*#+*##=  -%#.      *       %      .#%- .+*#**#+==*@@%=..                     //
//                          #@@+=%@    *@=  =%:     @#**+*#%@     [email protected]= [email protected]+    %#[email protected]@@                         //
//                          [email protected]#:.%%:   [email protected]= [email protected]:   [email protected]@@@@@@@@=   [email protected] [email protected]=   :%% -#@%.                         //
//                            #@=. =%#[email protected]@@@@@@  [email protected]@@@@@@@@@@+ [email protected]@@@@@@.:-#%= :[email protected]%.                          //
//                             [email protected]*-. [email protected]@-=. .*@@+%@@@@*-#=#@@@@%#@@+. [email protected]@. .-#%-                            //
//                               *@%+*@@:  [email protected]@@@@@@@@::-:[email protected]@@@@@@@@+.  [email protected]@*+%@#                              //
//                             :#@@@@@@@@@@@@@@@@@@@@---=-=*@@@@@@@@@@@@@@@@@@@@#=                            //
//                            +%@@@@@@@@@@@@@@@@@@@@==- - ==*@@@@@@@@@@@@@@@@@@@@@=                           //
//                            @@@@@@@@@@@@@@@@@@@@@- :. @ .. [email protected]@@@@@@@@@@@@@@@@@@@@.                          //
//                           [email protected]@@@@@@@@@@@@@@@@@@@:     @     [email protected]@@@@@@@@@@@@@@@@@@@-                          //
//                           [email protected]@@@@@@@@@@@@@@@@@@.      %      :@@@@@@@@@@@@@@@@@@@-                          //
//                           [email protected]@@@@@@@@@@@@@@@@@#:      *      :#@@@@@@@@@@@@@@@@@@+                          //
//                           *@@@@@@@@@@@@@@@@@@@@#+   [email protected]=  .+#@@@@@@@@@@@@@@@@@@@@*                          //
//                           [email protected]@@@@@@@@@@@@@@@@@@@@@@#*@@@*%@@@@@@@@@@@@@@@@@@@@@@@*                          //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MEIOSX is ERC1155Creator {
    constructor() ERC1155Creator("MEIOS_EX", "MEIOSX") {}
}